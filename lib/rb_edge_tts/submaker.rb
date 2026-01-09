# frozen_string_literal: true

require_relative 'srt_composer'

module RbEdgeTTS
  class SubMaker
    attr_reader :cues, :type

    def initialize
      @cues = []
      @type = nil
    end

    def feed(msg)
      raise ArgumentError, 'msg must be a TTSChunk' unless msg.is_a?(TTSChunk)
      raise ArgumentError, "Invalid message type, expected 'WordBoundary' or 'SentenceBoundary'." unless %w[
        WordBoundary SentenceBoundary
      ].include?(msg.type)

      @type = msg.type if @type.nil?
      raise ArgumentError, "Expected message type '#{@type}', but got '#{msg.type}'." if @type != msg.type

      start_time = msg.offset / 10_000_000.0
      end_time = (msg.offset + msg.duration) / 10_000_000.0
      subtitle = Subtitle.new(cues.size + 1, start_time, end_time, msg.text)
      @cues << subtitle
    end

    def get_srt
      SRTComposer.compose(@cues)
    end

    alias to_srt get_srt

    def to_s
      get_srt
    end
  end
end
