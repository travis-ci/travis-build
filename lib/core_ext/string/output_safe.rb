# frozen_string_literal: true

class String
  def output_safe
    dup.untaint
  end
end
