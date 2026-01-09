# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RbEdgeTTS::SubMaker do
  describe '#initialize' do
    it 'creates a submaker instance' do
      submaker = RbEdgeTTS::SubMaker.new
      expect(submaker.cues).to be_empty
      expect(submaker.type).to be_nil
    end
  end

  describe '#feed' do
    it 'feeds WordBoundary messages' do
      submaker = RbEdgeTTS::SubMaker.new
      chunk = RbEdgeTTS::TTSChunk.new(
        type: 'WordBoundary',
        offset: 0,
        duration: 100_000_000.0,
        text: 'Hello'
      )

      submaker.feed(chunk)
      expect(submaker.cues.size).to eq(1)
      expect(submaker.type).to eq('WordBoundary')
    end

    it 'raises error on invalid message type' do
      submaker = RbEdgeTTS::SubMaker.new
      chunk = RbEdgeTTS::TTSChunk.new(type: 'InvalidType')

      expect { submaker.feed(chunk) }.to raise_error(ArgumentError)
    end
  end

  describe '#get_srt' do
    it 'generates SRT format subtitles' do
      submaker = RbEdgeTTS::SubMaker.new
      chunk = RbEdgeTTS::TTSChunk.new(
        type: 'WordBoundary',
        offset: 0,
        duration: 100_000_000.0,
        text: 'Hello'
      )

      submaker.feed(chunk)
      srt = submaker.get_srt

      expect(srt).to include('1')
      expect(srt).to include('Hello')
    end
  end
end
