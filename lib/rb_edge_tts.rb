# frozen_string_literal: true

require 'eventmachine'
require 'faye/websocket'
require 'json'
require 'openssl'
require 'securerandom'
require 'time'

require_relative 'rb_edge_tts/typing'
require_relative 'rb_edge_tts/constants'
require_relative 'rb_edge_tts/drm'
require_relative 'rb_edge_tts/util'
require_relative 'rb_edge_tts/srt_composer'
require_relative 'rb_edge_tts/submaker'
require_relative 'rb_edge_tts/voices_manager'
require_relative 'rb_edge_tts/exceptions'
require_relative 'rb_edge_tts/communicate'
require_relative 'rb_edge_tts/version'
