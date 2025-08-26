module Fhir
  class ObservationPresenter

    attr_reader :observation

    def initialize(observation)
      @observation = observation
    end

    def as_json(_opts = nil)
      base = {
        resourceType: 'Observation',
        id: observation.id,
        status: observation.status || 'final',
        category: observation.category ? [{ text: observation.category }] : nil,
        code: { text: observation.code.presence || observation.type.demodulize },
        subject: { reference: "Patient/#{observation.patient.external_id}" },
        effectiveDateTime: observation.recorded_at&.iso8601
      }.compact

      if observation.respond_to?(:value) && observation.respond_to?(:unit) && observation.value.present?
        base[:valueQuantity] = {
          value: (observation.value.is_a?(String) ? observation.value.to_f : observation.value),
          unit: observation.unit
        }
      end

      # Interpretation (simple textual)
      if observation.respond_to?(:interpretation) && observation.interpretation.present?
        base[:interpretation] = [{ text: observation.interpretation }]
      end

      # Reference range for quantity-like observations
      rr = observation.try(:reference_range)
      if rr.present? && !observation.is_a?(Observation::BloodPressure)
        low = rr['low']
        high = rr['high']
        unit = rr['unit'] || observation.try(:unit)
        ref = {}
        ref[:low] = { value: low, unit: unit } if low
        ref[:high] = { value: high, unit: unit } if high
        ref[:text] = rr['text'] if rr['text']
        base[:referenceRange] = [ref] if ref.any?
      end

      if observation.is_a?(Observation::BloodPressure)
        components = []
        if observation.systolic.present?
          comp = {
            code: { text: 'Systolic blood pressure' },
            valueQuantity: { value: observation.systolic.to_f, unit: observation.unit || 'mmHg' }
          }
          if rr && rr['systolic']
            srr = rr['systolic']
            r = {}
            r[:low] = { value: srr['low'], unit: observation.unit || 'mmHg' } if srr['low']
            r[:high] = { value: srr['high'], unit: observation.unit || 'mmHg' } if srr['high']
            comp[:referenceRange] = [r] if r.any?
          end
          components << comp
        end
        if observation.diastolic.present?
          comp = {
            code: { text: 'Diastolic blood pressure' },
            valueQuantity: { value: observation.diastolic.to_f, unit: observation.unit || 'mmHg' }
          }
          if rr && rr['diastolic']
            drr = rr['diastolic']
            r = {}
            r[:low] = { value: drr['low'], unit: observation.unit || 'mmHg' } if drr['low']
            r[:high] = { value: drr['high'], unit: observation.unit || 'mmHg' } if drr['high']
            comp[:referenceRange] = [r] if r.any?
          end
          components << comp
        end
        base[:component] = components if components.any?
      end

      base
    end

  end
end
