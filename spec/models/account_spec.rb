require 'rails_helper'

RSpec.describe Account, type: :model do
  it 'requires a name' do
    expect(described_class.new(name: nil)).not_to be_valid
  end

  it 'generates a slug on create' do
    account = described_class.create!(name: 'Acme Health')
    expect(account.slug).to be_present
    expect(account.slug).to match(/acme-health/)
  end

  describe '.resolve' do
    it 'returns most recent when identifier is blank' do
      older = described_class.create!(name: 'Old')
      newer = described_class.create!(name: 'New')
      expect(described_class.resolve(nil)).to eq(newer)
      expect(described_class.resolve('')).to eq(newer)
    end

    it 'finds by id or slug' do
      account = described_class.create!(name: 'Lookup')
      expect(described_class.resolve(account.id)).to eq(account)
      expect(described_class.resolve(account.slug)).to eq(account)
    end
  end
end

