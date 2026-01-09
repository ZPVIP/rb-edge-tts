# frozen_string_literal: true

require 'eventmachine'
require 'faye/websocket'
require 'json'
require 'openssl'
require 'time'
require 'securerandom'

require_relative 'typing'
require_relative 'constants'
require_relative 'drm'
require_relative 'util'
require_relative 'srt_composer'
require_relative 'submaker'
require_relative 'voices_manager'

module RbEdgeTTS
  class Communicate
    attr_accessor :texts, :proxy, :state, :tts_config

    def initialize(text,
                   voice = RbEdgeTTS::DEFAULT_VOICE,
                   rate: '+0%',
                   volume: '+0%',
                   pitch: '+0Hz',
                   boundary: 'SentenceBoundary',
                   proxy: nil,
                   connect_timeout: 10,
                   receive_timeout: 60,
                   verbose: false)
      raise TypeError, 'text must be a string' unless text.is_a?(String)

      @tts_config = TTSConfig.new(voice, rate, volume, pitch, boundary)

      @texts = Util.split_text_by_byte_length(Util.escape_xml(Util.remove_incompatible_characters(text)), 4096).to_a

      @proxy = proxy
      raise TypeError, 'proxy must be a string' if proxy && !proxy.is_a?(String)

      raise TypeError, 'connect_timeout must be an integer' unless connect_timeout.is_a?(Integer)
      raise TypeError, 'receive_timeout must be an integer' unless receive_timeout.is_a?(Integer)

      @connect_timeout = connect_timeout
      @receive_timeout = receive_timeout
      @verbose = verbose

      @state = CommunicateState.new(
        partial_text: '',
        offset_compensation: 0,
        last_duration_offset: 0,
        stream_was_called: false
      )
    end

    def stream(&block)
      raise 'stream can only be called once.' if @state.stream_was_called

      @state.stream_was_called = true

      @texts.each do |partial_text|
        @state.partial_text = partial_text
        stream_internal(&block)
      end
    end

    def stream_sync
      queue = Thread::Queue.new

      thread = Thread.new do
        stream do |chunk|
          queue.push(chunk)
        end
        queue.push(nil)
      end

      Enumerator.new do |yielder|
        loop do
          chunk = queue.pop
          break if chunk.nil?

          yielder << chunk
        end
      ensure
        thread&.join
      end
    end

    def save(audio_fname, metadata_fname = nil, &block)
      raise TypeError, 'audio_fname must be a string' unless audio_fname.is_a?(String)
      raise TypeError, 'metadata_fname must be a string' if metadata_fname && !metadata_fname.is_a?(String)

      File.open(audio_fname, 'wb') do |audio_file|
        metadata_file = metadata_fname ? File.open(metadata_fname, 'w', encoding: 'utf-8') : nil

        stream do |chunk|
          if chunk.type == 'audio'
            audio_file.write(chunk.data)
          elsif metadata_file && %w[WordBoundary SentenceBoundary].include?(chunk.type)
            metadata_file.puts(JSON.generate(chunk.to_h))
            block.call(chunk) if block_given?
          end
        end
      ensure
        metadata_file&.close if metadata_file && metadata_file != audio_file
        audio_file.close
      end
    end

    def save_sync(audio_fname, metadata_fname = nil, &block)
      raise TypeError, 'audio_fname must be a string' unless audio_fname.is_a?(String)
      raise TypeError, 'metadata_fname must be a string' if metadata_fname && !metadata_fname.is_a?(String)

      Thread.new { save(audio_fname, metadata_fname, &block) }.join
    end

    private

    def stream_internal
      audio_was_received = false
      @ws = nil

      begin
        EventMachine.run do
          url = "#{RbEdgeTTS::WSS_URL}&ConnectionId=#{Util.connect_id}&Sec-MS-GEC=#{DRM.generate_sec_ms_gec}&Sec-MS-GEC-Version=#{RbEdgeTTS::SEC_MS_GEC_VERSION}"

          options = {
            headers: DRM.headers_with_muid(RbEdgeTTS::WSS_HEADERS),
            tls: {
              verify_peer: true,
              ca_file: OpenSSL::X509::DEFAULT_CERT_FILE
            }
          }

          @ws = Faye::WebSocket::Client.new(url, [], options)

          @ws.on :open do |_event|
            log 'WebSocket connection opened'
            send_command_request(@ws)
            send_ssml_request(@ws)
          end

          @ws.on :message do |event|
            handle_message(event.data) do |result|
              if result.type == 'audio'
                audio_was_received = true
              end
              yield result
            end
          end


          @ws.on :close do |event|
            # 1006 is common after successful transmission
            log "WebSocket connection closed: #{event.code} #{event.reason}" unless event.code == 1006
            EventMachine.stop
          end

          @ws.on :error do |event|
            # Ignore ECONNRESET as it often happens at the end of stream
            log "WebSocket Error: #{event.message}" unless event.message.to_s.include?('ECONNRESET')
            EventMachine.stop
          end

          EventMachine.add_timer(@receive_timeout) do
            puts "Timeout: No response in #{@receive_timeout} seconds"
            EventMachine.stop
          end
        end
      rescue StandardError => e
        raise unless e.message.include?('403')

        DRM.handle_client_response_error(e)
        retry
      end
    end

    def send_command_request(ws)
      log 'Sending command request:'
      request = DRM.command_request(@tts_config.boundary)
      log request
      ws.send(request)
    end

    def send_ssml_request(ws)
      ssml = Util.mkssml(@tts_config, @state.partial_text)

      request = "X-RequestId:#{Util.connect_id}\r\n" \
                "Content-Type:application/ssml+xml\r\n" \
                "X-Timestamp:#{Util.date_to_string}Z\r\n" \
                "Path:ssml\r\n\r\n" \
                "#{ssml}"

      ws.send(request)
    end

    def handle_message(data, &block)
      case data
      when String
        handle_text_message(data, &block)
      when Array
        handle_binary_message(data, &block)
      else
        handle_binary_message(data, &block)
      end
    end

    def handle_text_message(data, &block)
      return if data.nil? || data.empty?

      header_end = data.index("\r\n\r\n")
      unless header_end
        if data.length > 2
           handle_binary_message(data.bytes, &block)
           return
        end
      end
      return unless header_end

      headers = data[0...header_end]
      body = data[(header_end + 4)..-1]

      path = extract_header_value(headers, 'Path')
      if path.nil?
        if headers.include?('Path:audio')
           handle_binary_message(data.bytes, &block)
           return
        end
      end
      return unless path

      case path
      when 'audio.metadata'
        handle_metadata(body, &block)
        update_last_duration_offset(body)
      when 'audio'
        handle_binary_message(data.bytes, &block)
      when 'turn.end'
        update_offset_compensation
        @ws&.close
      when 'response', 'turn.start', 'path', 'SessionEnd'
        nil
      else
        raise UnknownResponse, "Unknown path received: #{path}"
      end
    end

    def handle_binary_message(data)
      return if data.nil? || data.length < 2

      header_length = (data[0] << 8) | data[1]

      if header_length > data.length
        raise UnexpectedResponse, 'The header length is greater than the length of the data.'
      end

      header_end = 2 + header_length
      headers = data[2...header_end].pack('C*').force_encoding('utf-8')
      body = data[header_end..-1].pack('C*')

      path = extract_header_value(headers, 'Path')

      raise UnexpectedResponse, "Received binary message, but the path is not audio: #{path}" if path != 'audio'

      content_type = extract_header_value(headers, 'Content-Type')

      if content_type && content_type != 'audio/mpeg'
        raise UnexpectedResponse, "Received binary message, but with an unexpected Content-Type: #{content_type}"
      end

      return if content_type.nil? && body.nil?

      return if body.nil? || body.empty?

      yield TTSChunk.new(type: 'audio', data: body)
    end

    def handle_metadata(data)
      return if data.nil? || data.empty?

      begin
        metadata = JSON.parse(data)
        return unless metadata.is_a?(Hash) && metadata['Metadata'].is_a?(Array)

        metadata['Metadata'].each do |meta_obj|
          meta_type = meta_obj['Type']
          next unless %w[WordBoundary SentenceBoundary].include?(meta_type)

          data_obj = meta_obj['Data']
          current_offset = (data_obj['Offset'] || 0) + @state.offset_compensation
          current_duration = data_obj['Duration'] || 0

          yield TTSChunk.new(
            type: meta_type,
            offset: current_offset,
            duration: current_duration,
            text: Util.unescape_xml(data_obj.dig('text', 'Text') || '')
          )
        end
      rescue JSON::ParserError => e
        puts "JSON parse error: #{e.message}"
      end
    end

    def extract_header_value(headers, key)
      return nil unless headers.is_a?(String)

      match = headers.match(/^#{Regexp.escape(key)}:([^\r\n]*)/i)
      match ? match[1].strip : nil
    end

    def update_last_duration_offset(data)
      metadata = JSON.parse(data)
      return unless metadata.is_a?(Hash) && metadata['Metadata'].is_a?(Array)

      metadata['Metadata'].each do |meta_obj|
        next unless %w[WordBoundary SentenceBoundary].include?(meta_obj['Type'])

        data_obj = meta_obj['Data']
        @state.last_duration_offset = (data_obj['Offset'] || 0) + (data_obj['Duration'] || 0)
      end
    rescue JSON::ParserError
      nil
    end

    def update_offset_compensation
      @state.offset_compensation = @state.last_duration_offset
      @state.offset_compensation += 8_750_000
    end

    def log(message)
      puts message if @verbose
    end
  end
end

