# frozen_string_literal: true

class String
  def to_bool
    %w[true yes 1 on].include?(downcase)
  end
end
