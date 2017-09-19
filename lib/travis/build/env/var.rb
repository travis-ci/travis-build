module Travis
  module Build
    class Env
      class Var
        PATTERN = /
        (?:SECURE\ )? # optionally starts with "SECURE "
        ([\w]+)= # left hand side, var name
          ( # right hand side is one of
            (?:[^"'`\ ]?("|'|`).*?((?<!\\)\3))+ # things quoted by ',",`, optionally preceded, one or more times
            |
            (?:[^\$]?\$\(.*?\))+ # $(things), optionally preceded by non-$, one or more times
            |
            [^"'\ ]+ # some bare word, not containing " or '
                      # (this includes many variations of things starting in $)
            |
            (?=\s) # an empty string (look for a space ahead)
            |
            \z # the end of the string
          )
        /x

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
