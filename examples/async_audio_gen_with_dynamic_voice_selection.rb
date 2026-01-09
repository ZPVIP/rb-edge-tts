#!/usr/bin/env ruby
# frozen_string_literal: true

require 'rb_edge_tts'
require 'async'

TEXT = 'Hoy es un buen día.'
OUTPUT_FILE = 'spanish.mp3'

Async do
  voices = RbEdgeTTS::VoicesManager.create
  voice = voices.find(locale: 'es', gender: 'Male')

  if voice.empty?
    puts 'No male Spanish voice found'
    exit 1
  end

  selected_voice = voice.sample
  puts "Using voice: #{selected_voice.name}"

  communicate = RbEdgeTTS::Communicate.new(TEXT, selected_voice.name)
  communicate.save(OUTPUT_FILE)

  puts "Audio saved to #{OUTPUT_FILE}"
end.wait
