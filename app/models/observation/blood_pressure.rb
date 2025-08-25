class Observation::BloodPressure < Observation
  store_accessor :data, :systolic, :diastolic, :unit

  validates :systolic, presence: true, numericality: { greater_than: 0 }
  validates :diastolic, presence: true, numericality: { greater_than: 0 }
  validates :unit, presence: true, inclusion: { in: %w[mmHg] }

  before_validation :set_defaults, on: :create

  def display_result
    "#{systolic}/#{diastolic} #{unit}"
  end

  private

    def set_defaults
      self.category ||= 'vital-signs'
      self.unit ||= 'mmHg'
    end
end