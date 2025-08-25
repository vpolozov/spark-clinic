class Observations::Fhir::IngestJob < ApplicationJob
  queue_as :default

  def perform(*args)
    account = Account.find(account_id)
    patient = account.patients.find_by!(external_id: attrs['patient_external_id'])

    value = BigDecimal(attrs['value'].to_s)
    value = value.round if account.settings['round_values']

    klass = (attrs['type'].presence || 'Observation').constantize rescue Observation
    klass.create!(
      account: account, patient: patient,
      code: attrs['code'], value_decimal: value, unit: attrs['unit'],
      recorded_at: Time.iso8601(attrs['recorded_at'])
    )
  end
end
