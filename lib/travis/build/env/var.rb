module Travis
  module Build
    class Env
      class Var
        PATTERN = /(?:SECURE )?([\w]+)=(("|')(.*?)(\3)|\$\(.*?\)|[^"' ]+)/

        class << self
          def parse(line)
            secure = line =~ /^SECURE /
            vars = line.scan(PATTERN).map { |var| var[0, 2] }
            vars = vars.map { |var| var << { secure: true } } if secure
            vars

          rescue Exception => e
            raise Travis::Build::EnvVarDefinitionError
          end

          def mark_secure(vars)
          end
        end

        attr_reader :key, :value, :type

        def initialize(key, value, options = {})
          @key = key.to_s
          @value = value.to_s.tap { |value| value.taint if options[:secure] }
          @type = options[:type]
          @secure = !!options[:secure]
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

        def secure?
          @secure
        end
      end
    end
  end
end
