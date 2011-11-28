class Module
  def load_constants!(loaded = [])
    constants.each do |name|
      full_name = [self.name, name].join('::')
      unless loaded.include?(full_name)
        loaded << full_name
        const = const_get(name)
        const.load_constants!(loaded) if const.is_a?(Class) || const.is_a?(Module)
      end
    end
  end
end
