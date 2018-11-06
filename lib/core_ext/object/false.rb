# frozen_string_literal: true

class Object
  def false?
    is_a?(FalseClass)
  end
end
