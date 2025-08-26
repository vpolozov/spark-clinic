require 'rails_helper'

RSpec.describe Observations::Fhir::IngestJob, type: :job do
  let!(:account) { Account.create!(name: 'Acme') }
  let!(:patient) { Patient.create!(account: account, external_id: 'P1', name: 'Alice') }

  it 'creates a glucose observation from FHIR-like params' do
    attrs = {
      'patient_external_id' => 'P1',
      'type' => 'glucose',
      'code' => 'Glucose observation',
      'recorded_at' => '2025-08-25T12:00:00Z',
      'value' => 100,
      'unit' => 'mg/dL'
    }

    expect {
      described_class.new.perform(account.id, attrs)
    }.to change { Observation::Glucose.count }.by(1)

    obs = Observation::Glucose.last
    expect(obs.account).to eq(account)
    expect(obs.patient).to eq(patient)
    expect(obs.code).to eq('Glucose observation')
    expect(obs.value.to_f).to eq(100.0)
    expect(obs.unit).to eq('mg/dL')
    expect(obs.status).to eq('final')
    expect(obs.recorded_at).to be_present
  end

  it 'creates a blood pressure observation using short type name' do
    attrs = {
      'patient_external_id' => 'P1',
      'type' => 'blood_pressure',
      'code' => 'BP',
      'recorded_at' => '2025-08-25T12:30:00Z',
      'systolic' => 120,
      'diastolic' => 80,
      'unit' => 'mmHg'
    }

    expect {
      described_class.new.perform(account.id, attrs)
    }.to change { Observation::BloodPressure.count }.by(1)

    bp = Observation::BloodPressure.last
    expect(bp.systolic.to_i).to eq(120)
    expect(bp.diastolic.to_i).to eq(80)
    expect(bp.unit).to eq('mmHg')
  end

  it 'falls back to current time if recorded_at is invalid' do
    attrs = {
      'patient_external_id' => 'P1',
      'type' => 'glucose',
      'code' => 'GLU',
      'recorded_at' => 'not-a-time',
      'value' => 90,
      'unit' => 'mg/dL'
    }

    now = Time.current
    described_class.new.perform(account.id, attrs)
    obs = Observation::Glucose.last
    expect(obs.recorded_at).to be_within(10.seconds).of(now)
  end
end
