class Observation::Weight < Observation
  store_accessor :data, :value, :unit

  validates :value, presence: true, numericality: { greater_than: 0 }
  validates :unit, presence: true, inclusion: { in: %w[kg lbs] }

  before_validation :set_defaults, on: :create

  private

  def set_defaults
    self.category ||= 'vital-signs'
    self.unit ||= 'kg'
  end
end