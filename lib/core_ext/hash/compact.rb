# frozen_string_literal: true

class Hash
  def compact
    each_with_object({}) do |(key, value), result|
      result[key] = value unless value.nil?
    end
  end
end
