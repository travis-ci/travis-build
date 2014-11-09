module Travis
  module Build
    class Env
      class Var
        PATTERN = /(?:SECURE )?([\w]+)=(("|')(.*?)(\3)|\$\(.*?\)|[^"' ]+)/

        class << self
          def parse(line)
            secure = line =~ /^SECURE /
            vars = line.scan(PATTERN).map { |var| var[0, 2] }
            vars = vars.map { |var| var << { secure: !!secure } } if secure
            vars
          end
        end

        attr_reader :key, :value, :type

        def initialize(key, value, options = {})
          @key = key.to_s
          @value = value.to_s.tap { |value| value.taint if options.delete(:secure) }
          @type = options[:type]
          @secure = value.tainted?
        end

        def valid?
          !key.empty?
        end

        def echo?
          !builtin?
        end

        def builtin?
          type == :builtin
        end

        def travis?
          @key =~ /^TRAVIS_/
        end

        def secure?
          value.tainted?
        end
      end
    end
  end
end
