module SpecHelpers
  module Payload
    def payload_for(type, language, extra = {})
      payload = PAYLOADS[type].deep_symbolize_keys
      payload = payload.deep_merge(config: { language: language })
      payload.deep_merge(extra)
    end
  end
end
