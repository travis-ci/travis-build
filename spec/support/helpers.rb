def deep_clone(object)
  Marshal.load(Marshal.dump(object))
end
