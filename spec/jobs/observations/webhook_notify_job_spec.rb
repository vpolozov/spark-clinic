require 'rails_helper'

RSpec.describe Observations::WebhookNotifyJob, type: :job do
  let(:account) { Account.create!(name: 'Acme', settings: { 'webhook_url' => 'http://example.com/hook' }) }
  let(:patient) { Patient.create!(account: account, external_id: 'P1', name: 'Alice') }

  it 'posts FHIR observation JSON to the webhook' do
    obs = Observation::Glucose.create!(account: account, patient: patient, status: 'final', recorded_at: Time.current, code: 'GLU', value: 100, unit: 'mg/dL')

    expect(Net::HTTP).to receive(:post) do |uri, body, headers|
      expect(uri).to be_a(URI)
      expect(uri.to_s).to eq('http://example.com/hook')
      json = JSON.parse(body)
      expect(json['resourceType']).to eq('Observation')
      expect(json['id']).to eq(obs.id)
      expect(headers['Content-Type']).to match('application/fhir+json; charset=utf-8')
    end.and_return(double('resp', code: '200'))

    described_class.new.perform(obs.id)
  end

  it 'no-ops if webhook_url blank' do
    account.update!(webhook_url: '')
    obs = Observation::Glucose.create!(account: account, patient: patient, status: 'final', recorded_at: Time.current, code: 'GLU', value: 90, unit: 'mg/dL')
    expect(Net::HTTP).not_to receive(:post)
    described_class.new.perform(obs.id)
  end
end

