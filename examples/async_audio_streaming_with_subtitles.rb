#!/usr/bin/env ruby
# frozen_string_literal: true

require 'rb_edge_tts'
require 'async'

TEXT = 'Hello World!'
VOICE = 'en-GB-SoniaNeural'
OUTPUT_FILE = 'test.mp3'
SRT_FILE = 'test.srt'

Async do
  communicate = RbEdgeTTS::Communicate.new(TEXT, VOICE)
  submaker = RbEdgeTTS::SubMaker.new

  File.open(OUTPUT_FILE, 'wb') do |file|
    communicate.stream do |chunk|
      if chunk.type == 'audio'
        file.write(chunk.data)
      elsif %w[WordBoundary SentenceBoundary].include?(chunk.type)
        submaker.feed(chunk)
      end
    end
  end

  File.write(SRT_FILE, submaker.get_srt)

  puts "Audio saved to #{OUTPUT_FILE}"
  puts "Subtitles saved to #{SRT_FILE}"
end.wait
