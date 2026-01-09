#!/usr/bin/env ruby
# frozen_string_literal: true

require 'rb_edge_tts'
require 'async'

TEXT = 'Hello World!'
VOICE = 'en-GB-SoniaNeural'
OUTPUT_FILE = 'test.mp3'

Async do
  communicate = RbEdgeTTS::Communicate.new(TEXT, VOICE)
  communicate.save(OUTPUT_FILE)

  puts "Audio saved to #{OUTPUT_FILE}"
end.wait
