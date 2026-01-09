# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RbEdgeTTS::DRM do
  describe '.generate_sec_ms_gec' do
    it 'generates a Sec-MS-GEC token' do
      token = RbEdgeTTS::DRM.generate_sec_ms_gec
      expect(token).to be_a(String)
      expect(token.length).to eq(64)
      expect(token).to match(/^[A-F0-9]+$/)
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
