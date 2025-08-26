class Account < ApplicationRecord
  has_many :patients, dependent: :destroy
  has_many :observations, dependent: :destroy

  store_accessor :settings, :theme,
                 #:round_values,
                 #:bp_systolic_high, :bp_diastolic_high, :glucose_high,
                 :webhook_url

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