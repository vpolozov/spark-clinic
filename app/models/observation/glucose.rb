class Observation::Glucose < Observation
  store_accessor :data, :value, :unit

  validates :value, presence: true, numericality: { greater_than: 0 }
  validates :unit, presence: true, inclusion: { in: %w[mg/dL mmol/L] }

  before_validation :set_defaults, on: :create

  private

  def set_defaults
    self.category ||= "laboratory"
    self.unit ||= "mg/dL"
  end
end
