# frozen_string_literal: true

class String
  def indent(level)
    split("\n").map { |line| ' ' * (level * 2) + line }.join("\n")
  end
end
