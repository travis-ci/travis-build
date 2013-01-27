class Hash
  # deep_merge_hash! by Stefan Rusterholz, see http://www.ruby-forum.com/topic/142809
  DEEP_MERGER = proc do |key, v1, v2|
    Hash === v1 && Hash === v2 ? v1.merge(v2, &DEEP_MERGER) : v2
  end

  def deep_merge(data)
    merge(data, &DEEP_MERGER)
  end unless Hash.method_defined?(:deep_merge)

  def deep_merge!(data)
    merge!(data, &DEEP_MERGER)
  end unless Hash.method_defined?(:deep_merge!)
end

