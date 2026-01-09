#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('lib', __dir__)
require 'rb_edge_tts'

puts 'Testing rb-edge-tts WebSocket connection...'

text = 'Hello, world!'

begin
  puts 'Creating Communicate instance...'
  communicate = RbEdgeTTS::Communicate.new(text)

  puts 'Starting stream...'
  audio_data = ''

  communicate.stream do |chunk|
    if chunk.type == 'audio'
      puts "Received audio chunk: #{chunk.data.length} bytes"
      audio_data += chunk.data
    elsif %w[WordBoundary SentenceBoundary].include?(chunk.type)
      puts "Received #{chunk.type}: #{chunk.text}"
    end
  end

  puts "Total audio data received: #{audio_data.length} bytes"

  if audio_data.length > 0
    File.write('test_output.mp3', audio_data, mode: 'wb')
    puts 'Audio saved to test_output.mp3'
  else
    puts 'ERROR: No audio data received!'
  end
rescue StandardError => e
  puts "ERROR: #{e.class}: #{e.message}"
  puts e.backtrace
end
