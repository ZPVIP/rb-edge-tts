# frozen_string_literal: true

require_relative 'lib/rb_edge_tts/version'

Gem::Specification.new do |spec|
  spec.name          = 'rb-edge-tts'
  spec.version       = RbEdgeTTS::VERSION
  spec.authors = ["Peng Zhang"]
  spec.email = ["zpregister@gmail.com"]

  spec.summary       = 'Ruby gem for Microsoft Edge\'s online text-to-speech service'
  spec.description   = 'A Ruby library and CLI tool to use Microsoft Edge\'s online TTS service from within Ruby code or using the provided rb-edge-tts or rb-edge-playback commands.'
  spec.homepage      = 'https://github.com/yourusername/rb-edge-tts'
  spec.license       = 'LGPL-3.0-or-later'
  spec.required_ruby_version = '>= 3.0.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/yourusername/rb-edge-tts'
  spec.metadata['changelog_uri'] = 'https://github.com/yourusername/rb-edge-tts/blob/main/CHANGELOG.md'

  spec.files = Dir.glob('{lib,exe,examples}/**/*') + %w[
    LICENSE
    README.md
    Rakefile
    rb-edge-tts.gemspec
    Gemfile
  ]
  spec.bindir        = 'exe'
  spec.executables   = %w[rb-edge-tts rb-edge-playback]
  spec.require_paths = ['lib']

  spec.add_dependency 'eventmachine', '~> 1.2'
  spec.add_dependency 'faye-websocket', '~> 0.11'
  spec.add_dependency 'json', '~> 2.6'
  spec.add_dependency 'terminal-table', '~> 3.0'

  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.12'
  spec.add_development_dependency 'rubocop', '~> 1.50'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.20'
  spec.add_development_dependency 'simplecov', '~> 0.22'
end
