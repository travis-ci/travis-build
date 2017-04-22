class String
  def to_bool
    return true if self =~ /^(t|true|yes|on|1)$/i
    return false if self.empty? || self =~ /^(f|false|no|off|0)$/i
    raise ArgumentError, "invalid bool #{self.inspect}"
  end
end
