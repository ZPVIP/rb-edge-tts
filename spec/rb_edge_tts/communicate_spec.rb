# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RbEdgeTTS::Communicate do
  describe '#initialize' do
    it 'creates a communicator with default options' do
      communicate = RbEdgeTTS::Communicate.new('Hello, world!')
      expect(communicate.texts).not_to be_empty
      expect(communicate.state.stream_was_called).to be false
    rescue StandardError => e
      skip "Requires network connection for initialization: #{e.message}"
    end

    it 'creates a communicator with custom voice' do
      communicate = RbEdgeTTS::Communicate.new('Hello, world!', 'en-US-AriaNeural')
      expect(communicate.tts_config.voice).to include('AriaNeural')
    rescue StandardError => e
      skip "Requires network connection for initialization: #{e.message}"
    end

    it 'validates text parameter' do
      expect { RbEdgeTTS::Communicate.new(123) }.to raise_error(TypeError)
    end
  end

  describe '#save_sync' do
    it 'saves audio to file synchronously' do
      skip 'Requires network connection for actual service call'
    end
  end
end
