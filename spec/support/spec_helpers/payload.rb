module SpecHelpers
  module Payload
    def payload_for(type, language)
      payload = PAYLOADS[type].deep_symbolize_keys
      payload.deep_merge(config: { language: language })
    end
  end
end
