# rb-edge-tts

[![Gem Version](https://badge.fury.io/rb/rb-edge-tts.svg)](https://badge.fury.io/rb/rb-edge-tts)
[![License: LGPL v3](https://img.shields.io/badge/License-LGPL%20v3-blue.svg)](https://www.gnu.org/licenses/lgpl-3.0)

Microsoft Edge Online Text-to-Speech Service (Ruby Gem).

This is a Ruby implementation of the Microsoft Edge Online Text-to-Speech (TTS) service. It provides a simple and easy-to-use interface, allowing you to use high-quality Edge TTS voices directly within your Ruby applications or via the command line.

This project is a port of the Python project [edge-tts](https://github.com/rany2/edge-tts).

## Features

- **High-Quality Voices**: Direct access to Microsoft Edge's online neural voices.
- **Multi-Language Support**: Supports 100+ languages and 400+ voices.
- **Highly Customizable**: Adjustable rate, volume, and pitch.
- **Subtitle Generation**: Supports generating subtitles in SRT format.
- **Command-Line Tools**: Includes `rb-edge-tts` and `rb-edge-playback` CLI tools.
- **Lightweight**: Removed unnecessary async dependencies, using standard Ruby libraries and efficient WebSocket handling.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rb-edge-tts'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install rb-edge-tts
```

## Quick Start

### Command Line Usage

`rb-edge-tts` provides a powerful command-line interface.

**Basic Usage: Generate MP3**

```bash
$ rb-edge-tts --text 'Hello, world!' --write-media hello.mp3
```

**Generate Audio and Subtitles**

```bash
$ rb-edge-tts --text 'Hello, world!' --write-media hello.mp3 --write-subtitles hello.srt
```

**Use a Specific Voice**

```bash
$ rb-edge-tts --text 'Hello, world!' --voice en-GB-SoniaNeural --write-media hello.mp3
$ rb-edge-tts -f test.txt --write-media test.mp3 -v de-DE-AmalaNeural
```

**Adjust Parameters (Rate, Volume, Pitch)**

```bash
$ rb-edge-tts --rate=+20% --volume=+10% --pitch=+5Hz --text 'Hello, world!' --write-media output.mp3
```

**Instant Playback**

Use the `rb-edge-playback` command to play the generated speech immediately (requires `mpv` installed):

```bash
$ rb-edge-playback --text 'Hello, world!'
```

**List All Available Voices**

```bash
$ rb-edge-tts --list-voices
```

### Ruby Library Usage

**Basic Example**

```ruby
require 'rb_edge_tts'

# Use default voice
communicate = RbEdgeTTS::Communicate.new('Hello, world!')
communicate.save("output.mp3")
```

**Advanced Example: Custom Parameters**

```ruby
require 'rb_edge_tts'

communicate = RbEdgeTTS::Communicate.new(
  'Hello, world!',
  "en-US-AriaNeural",
  rate: "+10%",      # Speed
  volume: "+20%",    # Volume
  pitch: "+5Hz"      # Pitch
)
communicate.save("output.mp3")
```

**Generating Subtitles**

```ruby
require 'rb_edge_tts'

communicate = RbEdgeTTS::Communicate.new('Hello, world!')
submaker = RbEdgeTTS::SubMaker.new

File.open("output.mp3", "wb") do |file|
  communicate.stream do |chunk|
    if chunk.type == "audio"
      file.write(chunk.data)
    elsif %w[WordBoundary SentenceBoundary].include?(chunk.type)
      submaker.feed(chunk)
    end
  end
end

File.write("output.srt", submaker.to_srt)
```

**Streaming**

```ruby
require 'rb_edge_tts'

communicate = RbEdgeTTS::Communicate.new('Hello, world!')

communicate.stream do |chunk|
  if chunk.type == "audio"
    # Process audio data chunk (chunk.data)
    print "." 
  end
end
```

## Voice Management

You can use `VoicesManager` to find and filter available voices.

```ruby
require 'rb_edge_tts'

# Get all available voices
voices = RbEdgeTTS::VoicesManager.create

# Find all Chinese (Simplified) Female voices
chinese_female_voices = voices.find(locale: "zh-CN", gender: "Female")

chinese_female_voices.each do |voice|
  puts "#{voice.short_name}: #{voice.friendly_name}"
end
```

## Development Guide

This section is for developers who want to contribute to `rb-edge-tts` or build from source.

### Requirements

- Ruby 3.0 or higher

### Local Setup

1.  **Clone the repository**

    ```bash
    git clone https://github.com/ZPVIP/rb-edge-tts.git
    cd rb-edge-tts
    ```

2.  **Install dependencies**

    ```bash
    bundle install
    ```

3.  **Run tests**

    We use `rspec` for testing.

    ```bash
    bundle exec rspec
    ```

### Local Build and Install

If you modified the code and want to test it locally:

1.  **Build the Gem**

    ```bash
    gem build rb-edge-tts.gemspec
    ```

    This will generate an `rb-edge-tts-<version>.gem` file.

2.  **Install the Gem**

    ```bash
    gem install ./rb-edge-tts-<version>.gem
    ```

3.  **Verify Installation**

    ```bash
    rb-edge-tts --version
    ```

### Publishing

To publish a new version to RubyGems (requires permissions):

1.  Update the version number in `lib/rb_edge_tts/version.rb`.
2.  Update `CHANGELOG.md`.
3.  Build and push:

    ```bash
    gem build rb-edge-tts.gemspec
    gem push rb-edge-tts-<version>.gem
    ```

## Dependencies

- `eventmachine`: For WebSocket event loop.
- `faye-websocket`: WebSocket client implementation.
- `json`: JSON data processing.
- `terminal-table`: For formatting CLI output.
- `net/http`: For fetching voice lists (Standard Library).

## License

This project is licensed under the [GNU Lesser General Public License v3.0 (LGPLv3)](LICENSE).

The `lib/rb_edge_tts/srt_composer.rb` file is licensed under the MIT License.

## Acknowledgments

This project is a Ruby port of the Python project [edge-tts](https://github.com/rany2/edge-tts). Thanks to [rany2](https://github.com/rany2) for developing the original version, making high-quality TTS conversion possible via the Edge interface.

For questions regarding Python implementation details, please refer to the original project.

---

[Fork on GitHub](https://github.com/zpvip/rb-edge-tts) | [Report an Issue](https://github.com/zpvip/rb-edge-tts/issues)
