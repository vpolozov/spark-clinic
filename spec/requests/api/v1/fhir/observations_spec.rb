require 'rails_helper'

RSpec.describe 'FHIR Observations API', type: :request do
  let!(:account) { Account.create!(name: 'Acme') }
  let!(:patient) { Patient.create!(account: account, external_id: 'P1', name: 'Alice') }

  def json
    JSON.parse(response.body)
  end

  describe 'GET /api/v1/fhir/observations' do
    it 'returns a FHIR Bundle with observations for the account' do
      Observation::Glucose.create!(account: account, patient: patient, status: 'final', recorded_at: Time.current, code: 'GLU', value: 95, unit: 'mg/dL')

      get '/api/v1/fhir/observations', params: { account: account.slug }

      expect(response).to have_http_status(:ok)
      expect(json['resourceType']).to eq('Bundle')
      expect(json['total']).to eq(1)
      entry = json['entry'].first
      expect(entry['resource']['resourceType']).to eq('Observation')
      expect(entry['resource']['subject']['reference']).to eq('Patient/P1')
      expect(entry['resource']['valueQuantity']).to include('unit' => 'mg/dL')
    end

    it 'filters by patient_external_id' do
      other = Patient.create!(account: account, external_id: 'P2', name: 'Bob')
      Observation::Glucose.create!(account: account, patient: patient, status: 'final', recorded_at: Time.current, code: 'GLU', value: 95, unit: 'mg/dL')
      Observation::Glucose.create!(account: account, patient: other, status: 'final', recorded_at: Time.current, code: 'GLU', value: 110, unit: 'mg/dL')

      get '/api/v1/fhir/observations', params: { account: account.slug, patient_external_id: 'P1' }

      expect(response).to have_http_status(:ok)
      expect(json['total']).to eq(1)
      expect(json['entry'].first['resource']['subject']['reference']).to eq('Patient/P1')
    end
  end

  describe 'POST /api/v1/fhir/observations' do
    it 'enqueues ingest job and returns 202' do
      payload = {
        patient_external_id: 'P1',
        type: 'glucose',
        code: 'GLU',
        recorded_at: '2025-08-25T12:00:00Z',
        value: 100,
        unit: 'mg/dL'
      }

      expect {
        post "/api/v1/fhir/observations?account=#{account.slug}", params: payload.to_json, headers: { 'CONTENT_TYPE' => 'application/json' }
      }.to have_enqueued_job(Observations::Fhir::IngestJob).with(account.id, hash_including('patient_external_id' => 'P1', 'code' => 'GLU'))

      expect(response).to have_http_status(:accepted)
    end
  end
end
