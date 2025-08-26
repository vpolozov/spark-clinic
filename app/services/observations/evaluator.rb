module Observations
  class Evaluator
    # Apply reference range and interpretation to an Observation
    def self.apply!(observation)
      account = observation.account
      return observation unless account

      rr = account.reference_range_for(observation.kind)
      interpretation = interpret(observation, rr)

      observation.reference_range = rr if rr.present?
      observation.interpretation = interpretation if interpretation.present?
      observation
    end

    def self.unit_for(observation) = observation.try(:unit)

    def self.interpret(observation, rr)
      return nil if rr.blank?

      if observation.is_a?(::Observation::BloodPressure)
        sys_rr = rr['systolic'] || {}
        dia_rr = rr['diastolic'] || {}
        sys = observation.try(:systolic)&.to_f
        dia = observation.try(:diastolic)&.to_f

        return 'high' if (sys && sys_rr['high'] && sys > sys_rr['high']) || (dia && dia_rr['high'] && dia > dia_rr['high'])
        return 'low'  if (sys && sys_rr['low']  && sys < sys_rr['low'])  || (dia && dia_rr['low']  && dia < dia_rr['low'])
        return 'normal'
      else
        val = observation.try(:value)
        return nil if val.nil?
        v = val.to_f
        return 'high' if rr['high'] && v > rr['high']
        return 'low'  if rr['low']  && v < rr['low']
        return 'normal'
      end
    end
  end
end

