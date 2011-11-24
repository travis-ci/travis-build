class Hash
  def compact
    inject({}) do |result, (key, value)|
      result[key] = value unless value.nil?
      result
    end
  end
end
