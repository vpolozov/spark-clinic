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
  describe 'evaluation callback (before_validation on create)' do
    it 'applies reference range and interpretation for glucose' do
      account.update!(settings: account.settings.merge('reference_ranges' => {
        'glucose' => { 'unit' => 'mg/dL', 'low' => 70, 'high' => 100 }
      }))

      obs = Observation::Glucose.create!(
        account: account,
        patient: patient,
        status: 'final',
        recorded_at: Time.current,
        code: 'GLU',
        value: 120,
        unit: 'mg/dL'
      )

      expect(obs.interpretation).to eq('high')
      expect(obs.reference_range).to include('low' => 70, 'high' => 100)
    end

    it 'applies component ranges and interpretation for blood pressure' do
      account.update!(settings: account.settings.merge('reference_ranges' => {
        'blood_pressure' => {
          'unit' => 'mmHg',
          'systolic' => { 'low' => 90, 'high' => 120 },
          'diastolic' => { 'low' => 60, 'high' => 80 }
        }
      }))

      obs = Observation::BloodPressure.create!(
        account: account,
        patient: patient,
        status: 'final',
        recorded_at: Time.current,
        code: 'BP',
        systolic: 125,
        diastolic: 85,
        unit: 'mmHg'
      )

      expect(obs.interpretation).to eq('high')
      expect(obs.reference_range['systolic']).to include('high' => 120)
      expect(obs.reference_range['diastolic']).to include('high' => 80)
    end
  end
end
