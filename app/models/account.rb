class Account < ApplicationRecord
  has_many :patients, dependent: :destroy
  has_many :observations, dependent: :destroy

  store_accessor :settings, :theme, :webhook_url

  validates :name, presence: true
  validates :slug,
            presence: true,
            uniqueness: true,
            format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/ },
            on: :create

  before_validation :generate_slug, on: :create

  def self.resolve(identifier)
    return order(created_at: :desc).first if identifier.blank?

    find_by(id: identifier) || find_by(slug: identifier)
  end

  # Returns the hash of reference ranges stored under settings['reference_ranges'].
  # Example shapes:
  # {
  #   "glucose": {"unit": "mg/dL", "low": 70, "high": 100},
  #   "GLU": {"unit": "mg/dL", "low": 70, "high": 100},
  #   "blood_pressure": {
  #     "unit": "mmHg",
  #     "systolic": {"low": 90, "high": 120},
  #     "diastolic": {"low": 60, "high": 80}
  #   }
  # }
  def reference_ranges
    settings.fetch('reference_ranges', {}) || {}
  end

  # Find a reference range for an observation by code or type.
  # Returns a hash or nil.
  def reference_range_for(kind)
    ranges = reference_ranges
    return nil if ranges.blank?
    rr = ranges[kind.to_s] if kind.present?
    rr.presence
  end

  private

    def generate_slug
      return if slug.present? && slug_changed? == false
      base = name.to_s.downcase
                 .gsub(/[^a-z0-9\- ]/, "")
                 .strip
                 .gsub(/\s+/, "-")
                 .gsub(/-+/, "-")
                 .delete_suffix("-clinic")
      base = "account" if base.blank?

      candidate = base
      suffix = 0
      while self.class.exists?(slug: candidate)
        suffix += 1
        candidate = "#{base}-#{suffix}"
      end
      self.slug = candidate
    end
end
