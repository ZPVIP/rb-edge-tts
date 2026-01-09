# frozen_string_literal: true

require 'json'

module RbEdgeTTS
  class VoicesManager
    attr_accessor :voices
    attr_reader :called_create

    def initialize
      @voices = []
      @called_create = false
    end

    def self.create(custom_voices = nil)
      voices_data = if custom_voices.nil?
                      EdgeTTS.list_voices_helper
                    else
                      custom_voices
                    end

      voices_manager = new
      voices_manager.voices = voices_data.map do |voice|
        language = voice.locale.split('-').first
        VoicesManagerVoice.new(
          name: voice.name,
          short_name: voice.short_name,
          gender: voice.gender,
          locale: voice.locale,
          suggested_codec: voice.suggested_codec,
          friendly_name: voice.friendly_name,
          status: voice.status,
          voice_tag: voice.voice_tag,
          language: language
        )
      end
      voices_manager.called_create = true
      voices_manager
    end

    def find(**kwargs)
      raise 'VoicesManager.find() called before VoicesManager.create()' unless @called_create

      voices.select do |voice|
        kwargs.all? do |key, value|
          send(key.to_s, voice) == value
        end
      end
    end

    def gender(voice)
      voice.gender
    end

    def locale(voice)
      voice.locale
    end

    def language(voice)
      voice.language
    end
  end

  def self.list_voices(connector: nil, proxy: nil)
    list_voices_helper(connector: connector, proxy: proxy)
  end

  def self.list_voices_helper(connector: nil, proxy: nil)
    url = "#{VOICE_LIST}&Sec-MS-GEC=#{DRM.generate_sec_ms_gec}&Sec-MS-GEC-Version=#{SEC_MS_GEC_VERSION}"
    headers = DRM.headers_with_muid(VOICE_HEADERS)

    require 'net/http'
    require 'uri'

    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER

    request = Net::HTTP::Get.new(uri)
    headers.each { |k, v| request[k] = v }

    response = http.request(request)
    raise UnexpectedResponse, "HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    body = JSON.parse(response.body)
    body.map do |voice_data|
      voice_data[:voice_tag] ||= {}
      voice_data[:voice_tag][:content_categories] ||= []
      voice_data[:voice_tag][:voice_personalities] ||= []

      voice_data = voice_data.transform_keys { |k| k.to_s.gsub(/([a-z])([A-Z])/, '\1_\2').downcase.to_sym }
      voice_data[:voice_tag] = VoiceTag.new(
        content_categories: voice_data.dig(:voice_tag, :content_categories) || [],
        voice_personalities: voice_data.dig(:voice_tag, :voice_personalities) || []
      )
      Voice.new(**voice_data)
    end
  end
end
