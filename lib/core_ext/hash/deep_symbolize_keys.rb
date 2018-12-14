# frozen_string_literal: true

class Hash
  unless Hash.method_defined?(:deep_symbolize_keys)
    def deep_symbolize_keys
      each_with_object({}) do |(key, value), result|
        key = deep_symbolize_key(key) || key
        result[key] = deep_symbolize_coerce_value(value)
      end
    end

    def deep_symbolize_key(key)
      key.to_sym
    rescue StandardError
      key
    end

    private :deep_symbolize_key

    def deep_symbolize_coerce_value(value)
      case value
      when Array
        value.map { |v| v.is_a?(Hash) ? v.deep_symbolize_keys : v }
      when Hash
        value.deep_symbolize_keys
      else
        value
      end
    end

    private :deep_symbolize_coerce_value
  end

  unless Hash.method_defined?(:deep_symbolize_keys!)
    def deep_symbolize_keys!
      replace(deep_symbolize_keys)
    end
  end
end
