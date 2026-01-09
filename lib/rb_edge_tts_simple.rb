# frozen_string_literal: true

require 'securerandom'
require 'async'
require 'async/http'
require 'async/io/stream'
require 'json'
require 'openssl'
require 'time'

module RbEdgeTTS
  VERSION = '7.2.7'
  VERSION_INFO = VERSION.split('.').map(&:to_i).freeze

  # Test basic functionality
  begin
    puts 'Module loaded successfully'
    puts "Version: #{VERSION}"
    puts "Sec-MS-GEC: #{DRM.generate_sec_ms_gec}"
    puts "MUID: #{DRM.generate_muid}"
  rescue StandardError => e
    puts "Error loading module: #{e.message}"
  end
end
