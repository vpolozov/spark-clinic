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
    patient = account.patients.find_by!(external_id: attrs["patient_external_id"])

    klass = Observation.resolve_class(attrs["type"])

    common = {
      account: account,
      patient: patient,
      status: attrs["status"].presence || "final",
      category: attrs["category"],
      code: attrs["code"],
      recorded_at: Utils::TimeUtils.parse_iso8601(attrs["recorded_at"])
    }

    attributes = case klass.kind
    when :blood_pressure
                   common.merge(
                     systolic: attrs["systolic"],
                     diastolic: attrs["diastolic"],
                     unit: attrs["unit"] || "mmHg"
                   )
    else
                   if attrs.key?("value") || attrs.key?("unit")
                     common.merge(value: attrs["value"], unit: attrs["unit"])
                   else
                     common
                   end
    end

    klass.create!(attributes)
  end
end
