# frozen_string_literal: true

module RbEdgeTTS
  class EdgeTTSException < StandardError; end
  class UnknownResponse < EdgeTTSException; end
  class UnexpectedResponse < EdgeTTSException; end
  class NoAudioReceived < EdgeTTSException; end
  class WebSocketError < EdgeTTSException; end
  class SkewAdjustmentError < EdgeTTSException; end
end
