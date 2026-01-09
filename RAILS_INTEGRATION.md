# Rails Integration Guide: Streaming Text-to-Speech

This guide explains how to integrate `rb-edge-tts` into a Rails application to provide **streaming** speech playback. This allows audio to start playing almost immediately, without waiting for the entire audio file to generate.

## 1. Prerequisites

Add the gem to your `Gemfile`:

```ruby
gem 'rb-edge-tts'
```

Run `bundle install`.

## 2. Controller Implementation

We will use `ActionController::Live` to stream audio data chunks directly to the browser as they are received from the Edge TTS service.

Create a new controller, e.g., `app/controllers/tts_controller.rb`:

```ruby
class TtsController < ApplicationController
  include ActionController::Live

  def speak
    head :bad_request and return unless params[:text].present?

    # Set headers for streaming MP3
    response.headers['Content-Type'] = 'audio/mpeg'
    response.headers['Content-Disposition'] = 'inline' # Play in browser
    response.headers['X-Accel-Buffering'] = 'no'       # Disable Nginx buffering if applicable

    # Initialize client
    # You might want to sanitize params[:text] or limit length here
    communicate = RbEdgeTTS::Communicate.new(
      params[:text],
      voice: 'en-US-EmmaMultilingualNeural' # or params[:voice]
    )

    begin
      # Stream audio chunks directly to the response stream
      communicate.stream do |chunk|
        if chunk.type == 'audio'
          response.stream.write(chunk.data)
        end
      end
    rescue => e
      Rails.logger.error "TTS Error: #{e.message}"
    ensure
      # Always close the stream
      response.stream.close
    end
  end
end
```

**Note:** `RbEdgeTTS::Communicate#stream` blocks the thread while `EventMachine` runs, effectively managing the stream loop for you.

## 3. Routes

Add a route in `config/routes.rb`:

```ruby
get 'tts/speak', to: 'tts#speak'
```

## 4. Frontend Implementation

You need a way to render the icon and handle the click event. The simplest approach uses an HTML5 `<audio>` element that plays the stream URL.

### A. View Helper (Optional)

Create a helper to render text with a speaker icon:

```ruby
# app/helpers/tts_helper.rb
module TtsHelper
  def speech_tag(text)
    content_tag(:div, class: "flex items-start gap-2") do
      concat content_tag(:p, text, class: "text-content")
      concat button_tag("🔊", 
        class: "tts-play-btn cursor-pointer text-blue-500 hover:text-blue-700",
        data: { text: text }
      )
    end
  end
end
```

### B. JavaScript (Stimulus Controller Recommended)

If using **Stimulus**:

```javascript
// app/javascript/controllers/tts_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  play(event) {
    const text = event.currentTarget.dataset.text
    if (!text) return

    // Don't play duplicate
    if (this.audio) { this.audio.pause() }

    // Build URL with params
    const params = new URLSearchParams({ text: text })
    const streamUrl = `${this.urlValue}?${params.toString()}`

    // Create and play audio
    this.audio = new Audio(streamUrl)
    this.audio.play().catch(error => console.error("Playback failed:", error))
    
    // Optional: Toggle icon state
    event.currentTarget.classList.add("opacity-50")
    this.audio.onended = () => event.currentTarget.classList.remove("opacity-50")
  }
}
```

**Usage in View:**

```erb
<div data-controller="tts" data-tts-url-value="<%= tts_speak_path %>">
  <%= speech_tag("Welcome to my blog post!") %>
  
  <p>
    Another paragraph. 
    <button data-action="click->tts#play" data-text="Another paragraph.">🔈</button>
  </p>
</div>
```

## 5. Deployment Considerations

*   **Web Server**: Ensure your web server (e.g., Puma) is configured to handle threads/concurrency, as streaming connections occupy a thread for the duration of playback.
*   **Timeouts**: Increase read timeouts if generating very long speeches.
*   **Caching**: Since TTS output for static text doesn't change often, consider HTTP caching (`ETag` or `Cache-Control`) if you want to avoid hitting the remote API repeatedly for the same text.
