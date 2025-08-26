require 'rails_helper'

RSpec.describe Observation, type: :model do
  let(:account) { Account.create!(name: 'Acme') }
  let(:patient) { Patient.create!(account: account, external_id: 'P1', name: 'Alice') }

  context 'base validation' do
    it 'requires status, recorded_at, type, patient, account' do
      obs = described_class.new
      expect(obs).not_to be_valid
      obs.assign_attributes(account: account, patient: patient, status: 'final', recorded_at: Time.current, type: 'Observation')
      expect(obs).to be_valid
    end
  end

  context 'glucose observation' do
    it 'is valid with minimal attributes and sets defaults' do
      glucose = Observation::Glucose.new(
        account: account,
        patient: patient,
        status: 'final',
        recorded_at: Time.current,
        code: 'GLU',
        value: 100,
        unit: 'mg/dL'
      )
      expect(glucose).to be_valid
      glucose.save!
      expect(glucose.category).to eq('laboratory')
      expect(glucose.display_result).to include('mg/dL')
    end
  end

  describe '.resolve_class' do
    it 'returns subclass for short name' do
      expect(described_class.resolve_class('glucose')).to eq(Observation::Glucose)
      expect(described_class.resolve_class('blood_pressure')).to eq(Observation::BloodPressure)
    end

    it 'returns class for fully qualified name' do
      expect(described_class.resolve_class('Observation::Weight')).to eq(Observation::Weight)
    end

    it 'falls back to Observation for unknown' do
      expect(described_class.resolve_class('Unknown::Type')).to eq(Observation)
      expect(described_class.resolve_class(nil)).to eq(Observation)
    end
  end

  describe 'webhook enqueue' do
    it 'enqueues notify job on create when webhook_url present' do
      account.update!(webhook_url: 'http://example.com/hook')
      expect {
        Observation::Glucose.create!(account: account, patient: patient, status: 'final', recorded_at: Time.current, code: 'GLU', value: 100, unit: 'mg/dL')
      }.to have_enqueued_job(Observations::WebhookNotifyJob)
    end

    it 'does not enqueue when webhook_url blank' do
      account.update!(webhook_url: '')
      expect {
        Observation::Glucose.create!(account: account, patient: patient, status: 'final', recorded_at: Time.current, code: 'GLU', value: 100, unit: 'mg/dL')
      }.not_to have_enqueued_job(Observations::WebhookNotifyJob)
    end
  end
end
