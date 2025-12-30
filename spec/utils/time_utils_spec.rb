require 'rails_helper'

RSpec.describe Utils::TimeUtils do
  describe '.parse_iso8601' do
    it 'parses a valid ISO8601 string' do
      t = described_class.parse_iso8601('2025-08-25T12:00:00Z')
      expect(t).to be_a(Time)
      expect(t.utc.strftime('%Y-%m-%dT%H:%M:%SZ')).to eq('2025-08-25T12:00:00Z')
    end

    it 'returns default when invalid or blank' do
      now = Time.current
      expect(described_class.parse_iso8601('not-a-time', default: now)).to eq(now)
      expect(described_class.parse_iso8601(nil, default: now)).to eq(now)
    end
  end
end
