# frozen_string_literal: true

class String
  def unindent
    gsub(/^#{self[/\A\s*/]}/, '')
  end
end
