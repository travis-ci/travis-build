module SpecHelpers
  module Payload
    def payload_for(type, language = nil, extra = {})
      payload = PAYLOADS[type].deep_symbolize_keys
      payload = payload.deep_merge(config: { language: language }) if language
      payload.deep_merge(extra)
    end
  end
end
