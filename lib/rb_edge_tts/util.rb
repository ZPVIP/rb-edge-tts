# frozen_string_literal: true

require 'cgi'

module RbEdgeTTS
  module Util
    class << self
      def get_headers_and_data(data, header_length)
        raise TypeError, 'data must be a string' unless data.is_a?(String)

        headers = {}
        data[0...header_length].split("\r\n").each do |line|
          key, value = line.split(':', 2)
          headers[key.strip] = value.strip if key && value
        end

        [headers, data[(header_length + 2)..-1]]
      end

      def remove_incompatible_characters(string)
        return string.encode('utf-8') if string.is_a?(String)
        return string.dup.force_encoding('utf-8') if string.is_a?(String)

        string.to_s
      end

      def connect_id
        SecureRandom.uuid.gsub('-', '')
      end

      def split_text_by_byte_length(text, byte_length)
        raise TypeError, 'text must be a string' unless text.is_a?(String)
        raise ArgumentError, 'byte_length must be greater than 0' if byte_length <= 0

        encoded_text = text.encode('utf-8')
        Enumerator.new do |yielder|
          while encoded_text.bytesize > byte_length
            split_at = find_last_newline_or_space_within_limit(encoded_text, byte_length)

            split_at = find_safe_utf8_split_point(encoded_text, byte_length) if split_at.nil? || split_at < 0

            split_at = adjust_split_point_for_xml_entity(encoded_text, split_at)

            raise ArgumentError, 'Maximum byte length is too small or invalid text structure' if split_at < 0

            chunk = encoded_text[0...split_at].strip
            yielder << chunk unless chunk.empty?

            encoded_text = encoded_text[(split_at > 0 ? split_at : 1)..-1]
          end

          remaining_chunk = encoded_text.strip
          yielder << remaining_chunk unless remaining_chunk.empty?
        end
      end

      def mkssml(tts_config, escaped_text)
        escaped_text = escaped_text.encode('utf-8') if escaped_text.is_a?(String)

        "<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xml:lang='en-US'>" \
          "<voice name='#{tts_config.voice}'>" \
          "<prosody pitch='#{tts_config.pitch}' rate='#{tts_config.rate}' volume='#{tts_config.volume}'>" \
          "#{escaped_text}" \
          '</prosody>' \
          '</voice>' \
          '</speak>'
      end

      def date_to_string
        Time.now.utc.strftime('%a %b %d %Y %H:%M:%S GMT+0000 (Coordinated Universal Time)')
      end

      def ssml_headers_plus_data(request_id, timestamp, ssml)
        <<~HEADERS
          X-RequestId:#{request_id}\r
          Content-Type:application/ssml+xml\r
          X-Timestamp:#{timestamp}Z\r
          Path:ssml\r
          \r
          #{ssml}
        HEADERS
      end

      def escape_xml(text)
        CGI.escapeHTML(text)
      end

      def unescape_xml(text)
        CGI.unescapeHTML(text)
      end

      private

      def find_last_newline_or_space_within_limit(text, limit)
        split_at = text.rindex("\n", [limit - 1, 0].max)
        split_at = text.rindex(' ', [limit - 1, 0].max) if split_at.nil? || split_at < 0
        split_at
      end

      def find_safe_utf8_split_point(text_segment, byte_length = text_segment.bytesize)
        split_at = [byte_length, text_segment.bytesize].min
        while split_at > 0
          begin
            text_segment.byteslice(0, split_at).encode('utf-8')
            return split_at
          rescue Encoding::UndefinedConversionError
            split_at -= 1
          end
        end
        split_at
      end

      def adjust_split_point_for_xml_entity(text, split_at)
        while split_at > 0 && text[0...split_at].include?('&')
          ampersand_index = text.rindex('&', split_at - 1)
          break if text.index(';', ampersand_index)&.< split_at

          split_at = ampersand_index
        end
        split_at
      end
    end
  end
end
