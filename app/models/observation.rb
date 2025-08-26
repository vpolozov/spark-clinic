class Observation < ApplicationRecord
  include AccountScoped

  belongs_to :patient

  # Validations for common attributes
  validates :status, presence: true, inclusion: { in: %w[final preliminary amended] }
  validates :recorded_at, presence: true
  validates :type, presence: true

  TYPES = {
    glucose: 'Observation::Glucose',
    blood_pressure: 'Observation::BloodPressure',
    weight: 'Observation::Weight'
  }.freeze

  # Scopes for common queries
  TYPES.each do |code, class_name|
    scope code, -> { where(type: class_name) }
  end

  scope :recent, -> { order(recorded_at: :desc) }

  def kind = TYPES.key(type)

  def display_result
    # Simple quantity
    if respond_to?(:value) || respond_to?(:unit)
      val = try(:value)
      return val.present? ? [val, try(:unit)].compact.join(" ") : "-"
    end

    "-"
  end

  def in_reference_range?
    return true if reference_range.empty? || value.nil?

    low = reference_range['low']
    high = reference_range['high']

    if low && high
      value >= low && value <= high
    elsif low
      value >= low
    elsif high
      value <= high
    else
      true
    end
  end

  # Resolve a class from a type string. Accepts:
  # - nil/blank -> Observation
  # - short names (glucose, blood_pressure, weight) -> corresponding STI subclass
  # - fully qualified class names (e.g., "Observation::Glucose")
  def self.resolve_class(type)
    return Observation if type.blank?

    mapped = TYPES[type.to_s.downcase.to_sym]
    return mapped.constantize if mapped

    type.constantize
  rescue NameError
    Observation
  end

end
