class String
  def unindent
    gsub /^#{self[/\A\s*/]}/, ''
  end
end
