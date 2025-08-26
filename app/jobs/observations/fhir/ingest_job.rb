class Observations::Fhir::IngestJob < ApplicationJob
  queue_as :default

  # Creates an Observation (or subclass) from a simple FHIR-like payload.
  # Expected attrs include:
  # - patient_external_id (required)
  # - type: e.g., "Observation::Glucose" or short names like "glucose", "blood_pressure" (optional)
  # - code: free-form or code system value (optional)
  # - recorded_at: ISO8601 timestamp (optional, defaults to now if invalid/missing)
  # - value/unit for quantity observations
  # - systolic/diastolic/unit for blood pressure
  def perform(account_id, attrs)
    account = Account.find(account_id)
    patient = account.patients.find_by!(external_id: attrs['patient_external_id'])

    klass = Observation.resolve_class(attrs['type'])

    common = {
      account: account,
      patient: patient,
      status: attrs['status'].presence || 'final',
      category: attrs['category'],
      code: attrs['code'],
      recorded_at: Utils::TimeUtils.parse_iso8601(attrs['recorded_at'])
    }

    attributes = case klass.name
                 when 'Observation::BloodPressure'
                   common.merge(
                     systolic: attrs['systolic'],
                     diastolic: attrs['diastolic'],
                     unit: attrs['unit'] || 'mmHg'
                   )
                 else
                   if attrs.key?('value') || attrs.key?('unit')
                     common.merge(value: attrs['value'], unit: attrs['unit'])
                   else
                     common
                   end
                 end

    rr = account.reference_range_for(klass.kind)
    interpretation = compute_interpretation(klass, attributes, rr)
    attributes[:reference_range] = rr if rr.present?
    attributes[:interpretation] = interpretation if interpretation.present?

    klass.create!(attributes)
  end

  private

  def compute_interpretation(klass, attrs, rr)
    return nil if rr.blank?
    if klass.name == 'Observation::BloodPressure'
      sys_rr = rr['systolic'] || {}
      dia_rr = rr['diastolic'] || {}
      sys = attrs[:systolic].to_f if attrs[:systolic]
      dia = attrs[:diastolic].to_f if attrs[:diastolic]
      return 'high' if (sys && sys_rr['high'] && sys > sys_rr['high']) || (dia && dia_rr['high'] && dia > dia_rr['high'])
      return 'low'  if (sys && sys_rr['low']  && sys < sys_rr['low'])  || (dia && dia_rr['low']  && dia < dia_rr['low'])
      return 'normal'
    else
      val = attrs[:value]
      return nil if val.nil?
      v = val.to_f
      return 'high' if rr['high'] && v > rr['high']
      return 'low'  if rr['low']  && v < rr['low']
      return 'normal'
    end
  end

end
