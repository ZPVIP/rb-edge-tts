# frozen_string_literal: true

module RbEdgeTTS
  class Subtitle
    attr_reader :index, :start, :end, :content

    def initialize(index, start_time, end_time, content)
      @index = index
      @start = start_time
      @end = end_time
      @content = content
    end

    def to_srt(eol = "\n")
      output_content = make_legal_content(content)
      output_content = output_content.gsub("\n", eol) if eol != "\n"

      template = "#{index}#{eol}#{timedelta_to_srt_timestamp(start)} --> #{timedelta_to_srt_timestamp(@end)}#{eol}#{output_content}#{eol}#{eol}"
      template
    end

    def <=>(other)
      [start, @end, index] <=> [other.start, other.end, other.index]
    end

    def hash
      [index, start, @end, content].hash
    end

    alias eql? ==

    private

    def make_legal_content(content_str)
      return content_str unless content_str.start_with?("\n") || content_str.include?("\n\n")

      content_str.strip.split(/\n\n+/).join("\n")
    end

    def timedelta_to_srt_timestamp(time_delta)
      total_seconds = time_delta.to_i
      hours, remainder = total_seconds.divmod(3600)
      minutes, seconds = remainder.divmod(60)
      milliseconds = (time_delta * 1000).to_i % 1000

      format('%02d:%02d:%02d,%03d', hours, minutes, seconds, milliseconds)
    end
  end

  module SRTComposer
    SECONDS_IN_HOUR = 3600
    SECONDS_IN_MINUTE = 60

    def self.compose(subtitles, reindex: true, start_index: 1, eol: "\n")
      subtitles_to_use = reindex ? sort_and_reindex(subtitles, start_index:) : subtitles
      subtitles_to_use.map { |sub| sub.to_srt(eol) }.join
    end

    def self.sort_and_reindex(subtitles, start_index: 1)
      sorted_subs = subtitles.sort
      result = []
      current_index = start_index

      sorted_subs.each do |sub|
        next unless should_include_subtitle?(sub)

        new_sub = Subtitle.new(current_index, sub.start, sub.end, sub.content)
        result << new_sub
        current_index += 1
      end

      result
    end

    class << self
      private

      def should_include_subtitle?(subtitle)
        return false if content_empty?(subtitle)
        return false if negative_start_time?(subtitle)
        return false if invalid_time_range?(subtitle)

        true
      end

      def content_empty?(subtitle)
        subtitle.content.strip.empty?
      end

      def negative_start_time?(subtitle)
        subtitle.start < 0
      end

      def invalid_time_range?(subtitle)
        subtitle.start >= subtitle.end
      end
    end
  end
end
