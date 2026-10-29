# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RbEdgeTTS::DRM do
  describe '.generate_sec_ms_gec' do
    it 'generates a v2 Sec-MS-GEC token (<16 hex>-<64 hex>)' do
      token = RbEdgeTTS::DRM.generate_sec_ms_gec
      expect(token).to match(/\A[A-F0-9]{16}-[A-F0-9]{64}\z/)
    end

    it 'is stable within a 5-minute window and changes across windows' do
      base = 1_761_600_000
      window = RbEdgeTTS::DRM.generate_sec_ms_gec(base)
      expect(RbEdgeTTS::DRM.generate_sec_ms_gec(base + 299)).to eq(window)
      expect(RbEdgeTTS::DRM.generate_sec_ms_gec(base + 300)).not_to eq(window)
    end

    # Regression pin for the hand-ported digest. The same code's token for the
    # then-current window was accepted by the live service (2026-10-28: voice
    # list 200, synthesis streamed audio).
    it 'produces the known token for a fixed timestamp' do
      expect(RbEdgeTTS::DRM.generate_sec_ms_gec(1_761_600_000)).to eq('2E35E683F6E3EEF9-ACC6E18CDE9E31DD20FA1F06D71A048C2E12A47C007A19FA4FD78E3F1550DD0F')
    end
  end

  describe '.generate_muid' do
    it 'generates a random MUID' do
      muid = RbEdgeTTS::DRM.generate_muid
      expect(muid).to be_a(String)
      expect(muid.length).to eq(32)
      expect(muid).to match(/^[A-F0-9]+$/)
    end

    it 'generates different MUIDs' do
      muid1 = RbEdgeTTS::DRM.generate_muid
      muid2 = RbEdgeTTS::DRM.generate_muid
      expect(muid1).not_to eq(muid2)
    end
  end

  describe '.get_unix_timestamp' do
    it 'returns a timestamp' do
      timestamp = RbEdgeTTS::DRM.get_unix_timestamp
      expect(timestamp).to be_a(Numeric)
      expect(timestamp).to be > 1_600_000_000
    end
  end

  describe '.parse_rfc2616_date' do
    it 'parses RFC 2616 date string' do
      date_string = 'Tue, 15 Nov 1994 08:12:31 GMT'
      timestamp = RbEdgeTTS::DRM.parse_rfc2616_date(date_string)
      expect(timestamp).to be_within(10_000).of(784_877_551)
    end

    it 'returns nil for invalid date' do
      timestamp = RbEdgeTTS::DRM.parse_rfc2616_date('invalid')
      expect(timestamp).to be_nil
    end
  end
end
