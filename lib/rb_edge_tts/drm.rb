# frozen_string_literal: true

require 'digest'
require 'securerandom'
require 'time'

module RbEdgeTTS
  class DRM
    @clock_skew_seconds = 0.0

    WIN_EPOCH = 11_644_473_600
    S_TO_NS = 1_000_000_000

    class << self
      attr_accessor :clock_skew_seconds

      def adj_clock_skew_seconds(skew_seconds)
        @clock_skew_seconds += skew_seconds
      end

      def get_unix_timestamp
        Time.now.utc.to_f + @clock_skew_seconds
      end

      def parse_rfc2616_date(date_string)
        Time.rfc2822(date_string)&.to_f
      rescue ArgumentError, TypeError
        nil
      end

      def handle_client_response_error(error)
        raise SkewAdjustmentError, 'No server date in headers.' unless error.headers

        server_date = error.headers['Date'] || error.headers['date']
        raise SkewAdjustmentError, 'No server date in headers.' unless server_date

        server_date_parsed = parse_rfc2616_date(server_date)
        raise SkewAdjustmentError, "Failed to parse server date: #{server_date}" unless server_date_parsed

        client_date = get_unix_timestamp
        adj_clock_skew_seconds(server_date_parsed - client_date)
      end

      def generate_sec_ms_gec
        ticks = get_unix_timestamp
        ticks += WIN_EPOCH
        ticks -= (ticks % 300)
        ticks = (ticks * S_TO_NS / 100).round

        str_to_hash = "#{ticks.to_i}#{TRUSTED_CLIENT_TOKEN}"
        Digest::SHA256.hexdigest(str_to_hash).upcase
      end

      def command_request(boundary)
        word_boundary = boundary == 'WordBoundary'
        wd = word_boundary ? 'true' : 'false'
        sq = !word_boundary ? 'true' : 'false'

        "X-Timestamp:#{Util.date_to_string}\r\n" \
          "Content-Type:application/json; charset=utf-8\r\n" \
          "Path:speech.config\r\n\r\n" \
          '{"context":{"synthesis":{"audio":{"metadataoptions":{' \
          "\"sentenceBoundaryEnabled\":\"#{sq}\",\"wordBoundaryEnabled\":\"#{wd}\"" \
          '},' \
          '"outputFormat":"audio-24khz-48kbitrate-mono-mp3"' \
          '}}}}'
      end

      def generate_muid
        SecureRandom.hex(16).upcase
      end

      def headers_with_muid(headers)
        combined_headers = headers.dup
        raise ArgumentError, 'Headers already contain Cookie' if combined_headers.key?('Cookie')

        combined_headers['Cookie'] = "muid=#{generate_muid};"
        combined_headers
      end
    end
  end
end
