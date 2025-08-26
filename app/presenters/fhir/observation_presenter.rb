module Fhir
  class ObservationPresenter
    def initialize(observation)
      @observation = observation
    end

    def as_json(_opts = nil)
      base = {
        resourceType: 'Observation',
        id: observation.id,
        status: observation.status || 'final',
        category: observation.category ? [{ text: observation.category }] : nil,
        code: { text: observation.code.presence || observation.kind },
        subject: { reference: "Patient/#{observation.patient.external_id}" },
        effectiveDateTime: observation.recorded_at&.iso8601
      }.compact

      if observation.respond_to?(:value) && observation.respond_to?(:unit) && observation.value.present?
        base[:valueQuantity] = {
          value: (observation.value.is_a?(String) ? observation.value.to_f : observation.value),
          unit: observation.unit
        }
      end

      if observation.is_a?(Observation::BloodPressure)
        components = []
        if observation.respond_to?(:systolic) && observation.systolic.present?
          components << {
            code: { text: 'Systolic blood pressure' },
            valueQuantity: { value: observation.systolic.to_f, unit: observation.unit || 'mmHg' }
          }
        end
        if observation.respond_to?(:diastolic) && observation.diastolic.present?
          components << {
            code: { text: 'Diastolic blood pressure' },
            valueQuantity: { value: observation.diastolic.to_f, unit: observation.unit || 'mmHg' }
          }
        end
        base[:component] = components if components.any?
      end

      base
    end

    private

      attr_reader :observation
  end
end

