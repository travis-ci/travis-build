class Module
  def load_constants!(loaded = [])
    constants.each do |name|
      next if loaded.include?(name)
      loaded << name
      const = const_get(name)
      const.load_constants!(loaded) if const.is_a?(Class) || const.is_a?(Module)
    end
  end
end
