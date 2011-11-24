# heavily inspired by https://gist.github.com/268611

# apparently this mixes up lookup paths for constants

raise "experimental. shouldn't use this"

class Class
  private
    def prepend(mod = nil, &block)
      extend!.send(:include, mod || Module.new(&block))
    end

    def extend!
      tokens = name.split('::')
      name = tokens.pop
      namespace = tokens.empty? ? Object : eval(tokens.join('::'))

      original = namespace.__send__(:remove_const, name)
      namespace.const_set name, Class.new(original) {
        original.instance_variables.each do |name|
          instance_variable_set(name, original.instance_variable_get(name))
        end

        original.constants.each do |name|
          if original.autoload?(name)
            autoload name, original.autoload?(name)
          else
            const_set name, original.const_get(name) rescue nil
          end
        end
      }
    end
end
