# frozen_string_literal: true

module RbEdgeTTS
  TTSChunk = Struct.new(:type, :data, :offset, :duration, :text, keyword_init: true)

  VoiceTag = Struct.new(:content_categories, :voice_personalities, keyword_init: true)

  Voice = Struct.new(
    :name,
    :short_name,
    :gender,
    :locale,
    :suggested_codec,
    :friendly_name,
    :status,
    :voice_tag,
    keyword_init: true
  )

  VoicesManagerVoice = Struct.new(
    :name,
    :short_name,
    :gender,
    :locale,
    :suggested_codec,
    :friendly_name,
    :status,
    :voice_tag,
    :language,
    keyword_init: true
  )

  CommunicateState = Struct.new(
    :partial_text,
    :offset_compensation,
    :last_duration_offset,
    :stream_was_called,
    keyword_init: true
  )

  class TTSConfig
    attr_reader :voice, :rate, :volume, :pitch, :boundary

    def initialize(voice, rate, volume, pitch, boundary)
      validate_voice!(voice)
      @voice = normalize_voice(voice)
      @rate = validate_string_param('rate', rate, /^[+-]\d+%$/)
      @volume = validate_string_param('volume', volume, /^[+-]\d+%$/)
      @pitch = validate_string_param('pitch', pitch, /^[+-]\d+Hz$/)
      @boundary = validate_boundary(boundary)
    end

    private

    def validate_voice!(voice)
      raise TypeError, 'voice must be a string' unless voice.is_a?(String)
    end

    def normalize_voice(voice)
      # Check if voice is in short format (e.g., "en-US-EmmaMultilingualNeural")
      match = voice.match(/^([a-z]{2,})-([A-Z]{2,})-(.+Neural)$/)
      if match
        lang = match[1]
        region = match[2]
        name = match[3]

        # Handle names with hyphens (e.g., "en-US-JennyNeural-Angry")
        if name.include?('-')
          region = "#{region}-#{name[0...name.index('-')]}"
          name = name[(name.index('-') + 1)..-1]
        end

        return "Microsoft Server Speech Text to Speech Voice (#{lang}-#{region}, #{name})"
      end

      voice
    end

    def validate_string_param(param_name, param_value, pattern)
      raise TypeError, "#{param_name} must be a string" unless param_value.is_a?(String)
      raise ArgumentError, "Invalid #{param_name} '#{param_value}'" unless param_value.match?(pattern)

      param_value
    end

    def validate_boundary(boundary)
      raise TypeError, 'boundary must be a string' unless boundary.is_a?(String)
      raise ArgumentError, "Invalid boundary '#{boundary}'" unless %w[WordBoundary SentenceBoundary].include?(boundary)

      boundary
    end
  end
end
