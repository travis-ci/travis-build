class String
  def to_bool
    %w[true yes 1 on].include?(self.downcase)
  end
end
