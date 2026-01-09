# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RbEdgeTTS::Subtitle do
  describe '#initialize' do
    it 'creates a subtitle with index, times, and content' do
      subtitle = RbEdgeTTS::Subtitle.new(1, 0, 100, 'Hello')
      expect(subtitle.index).to eq(1)
      expect(subtitle.start).to eq(0)
      expect(subtitle.end).to eq(100)
      expect(subtitle.content).to eq('Hello')
    end
  end

  describe '#to_srt' do
    it 'generates SRT format string' do
      subtitle = RbEdgeTTS::Subtitle.new(1, 0, 0.1, 'Hello')
      srt = subtitle.to_srt

      expect(srt).to include('1')
      expect(srt).to include('00:00:00,000')
      expect(srt).to include('00:00:00,100')
      expect(srt).to include('Hello')
    end
  end
end

RSpec.describe RbEdgeTTS::SRTComposer do
  describe '.compose' do
    it 'composes SRT from subtitles' do
      subtitles = [
        RbEdgeTTS::Subtitle.new(1, 0, 0.1, 'Hello'),
        RbEdgeTTS::Subtitle.new(2, 0.1, 0.2, 'World')
      ]

      srt = RbEdgeTTS::SRTComposer.compose(subtitles)
      expect(srt).to include('Hello')
      expect(srt).to include('World')
    end
  end

  describe '.sort_and_reindex' do
    it 'sorts and reindexes subtitles' do
      subtitles = [
        RbEdgeTTS::Subtitle.new(2, 0.1, 0.2, 'Second'),
        RbEdgeTTS::Subtitle.new(1, 0, 0.1, 'First')
      ]

      sorted = RbEdgeTTS::SRTComposer.sort_and_reindex(subtitles)
      expect(sorted.first.content).to eq('First')
      expect(sorted.last.content).to eq('Second')
    end
  end
end
