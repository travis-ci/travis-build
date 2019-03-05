# frozen_string_literal: true

class Hash
  # deep_merge_hash! by Stefan Rusterholz, see http://www.ruby-forum.com/topic/142809
  DEEP_MERGER = proc do |_key, v1, v2|
    v1.is_a?(Hash) && v2.is_a?(Hash) ? v1.merge(v2, &DEEP_MERGER) : v2
  end

  unless Hash.method_defined?(:deep_merge)
    def deep_merge(data)
      merge(data, &DEEP_MERGER)
    end
  end

  unless Hash.method_defined?(:deep_merge!)
    def deep_merge!(data)
      merge!(data, &DEEP_MERGER)
    end
  end
end
