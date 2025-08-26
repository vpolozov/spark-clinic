require 'rails_helper'

RSpec.describe Patient, type: :model do
  let(:account) { Account.create!(name: 'Acme') }

  it 'is invalid without external_id' do
    patient = described_class.new(account: account, name: 'Alice')
    expect(patient).not_to be_valid
    patient.external_id = 'P123'
    expect(patient).to be_valid
  end

  it 'is invalid without name' do
    patient = described_class.new(account: account, external_id: 'P123')
    expect(patient).not_to be_valid
    patient.name = 'Alice'
    expect(patient).to be_valid
  end

  it 'enforces external_id uniqueness scoped to account' do
    described_class.create!(account: account, external_id: 'P123', name: 'Alice')
    dup = described_class.new(account: account, external_id: 'P123', name: 'Bob')
    expect(dup).not_to be_valid

    other_account = Account.create!(name: 'Beta')
    ok = described_class.new(account: other_account, external_id: 'P123', name: 'Charlie')
    expect(ok).to be_valid
  end
end

