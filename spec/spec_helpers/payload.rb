module SpecHelpers
  module Payload
    def payload_for(type, language = nil, extra = {})
      payload = Marshal.load(
        Marshal.dump(
          PAYLOADS.fetch(type).deep_symbolize_keys
        )
      )

      if language
        language = language.to_s
        payload.deep_merge!(config: { language: language })

        payload.deep_merge!(
          Marshal.load(
            Marshal.dump(
              PAYLOAD_LANGUAGE_OVERRIDES.fetch(
                language.to_sym, {}
              ).deep_symbolize_keys
            )
          )
        )
      end

      payload.deep_merge(extra).taint
    end
  end
end
