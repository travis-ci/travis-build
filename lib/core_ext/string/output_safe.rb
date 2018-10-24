class String
  def output_safe
    self.dup.untaint
  end
end
