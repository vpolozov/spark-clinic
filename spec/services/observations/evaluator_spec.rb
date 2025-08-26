require 'rails_helper'

RSpec.describe Observations::Evaluator do
  let(:account) { Account.create!(name: 'Acme') }
  let(:patient) { Patient.create!(account: account, external_id: 'P1', name: 'Alice') }

  describe '.apply!' do
    context 'quantity observation (glucose)' do
      before do
        account.update!(reference_ranges: {
            'glucose' => { 'unit' => 'mg/dL', 'low' => 70, 'high' => 100 }
          }
        )
      end

      it 'sets interpretation to high when above range and assigns reference_range' do
        obs = Observation::Glucose.new(account: account, patient: patient, status: 'final',
                                       recorded_at: Time.current, code: 'GLU', value: 120, unit: 'mg/dL')

        described_class.apply!(obs)

        expect(obs.reference_range).to include('low' => 70, 'high' => 100)
        expect(obs.interpretation).to eq('high')
      end

      it 'sets interpretation to normal when within range' do
        obs = Observation::Glucose.new(account: account, patient: patient, status: 'final',
                                       recorded_at: Time.current, code: 'GLU', value: 80, unit: 'mg/dL')

        described_class.apply!(obs)
        expect(obs.interpretation).to eq('normal')
      end

      it 'sets interpretation to low when below range' do
        obs = Observation::Glucose.new(account: account, patient: patient, status: 'final',
                                       recorded_at: Time.current, code: 'GLU', value: 60, unit: 'mg/dL')

        described_class.apply!(obs)
        expect(obs.interpretation).to eq('low')
      end
    end

    context 'blood pressure observation' do
      before do
        account.update!(reference_ranges: {
            'blood_pressure' => {
              'unit' => 'mmHg',
              'systolic' => { 'low' => 90, 'high' => 120 },
              'diastolic' => { 'low' => 60, 'high' => 80 }
            }
          }
        )
      end

      it 'marks high when either systolic or diastolic above range and assigns component ranges' do
        obs = Observation::BloodPressure.new(account: account, patient: patient, status: 'final',
                                             recorded_at: Time.current, code: 'BP', systolic: 125, diastolic: 85,
                                             unit: 'mmHg')

        described_class.apply!(obs)
        expect(obs.interpretation).to eq('high')
        expect(obs.reference_range['systolic']).to include('high' => 120)
        expect(obs.reference_range['diastolic']).to include('high' => 80)
      end

      it 'marks normal when both are within range' do
        obs = Observation::BloodPressure.new(account: account, patient: patient, status: 'final',
                                             recorded_at: Time.current, code: 'BP', systolic: 110, diastolic: 70,
                                             unit: 'mmHg')

        described_class.apply!(obs)
        expect(obs.interpretation).to eq('normal')
      end

      it 'marks low when either component is below range' do
        obs = Observation::BloodPressure.new(account: account, patient: patient, status: 'final',
                                             recorded_at: Time.current, code: 'BP', systolic: 85, diastolic: 55,
                                             unit: 'mmHg')

        described_class.apply!(obs)
        expect(obs.interpretation).to eq('low')
      end
    end

    it 'no-ops if observation has no account' do
      obs = Observation::Glucose.new(patient: patient, status: 'final', recorded_at: Time.current,
                                     code: 'GLU', value: 80, unit: 'mg/dL')
      expect { described_class.apply!(obs) }.not_to raise_error
      expect(obs.interpretation).to be_nil
    end
  end
end
