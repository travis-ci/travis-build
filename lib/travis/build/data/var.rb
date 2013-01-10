module Travis
  module Build
    class Data
      class Var
        class << self
          def create(*args)
            # TODO parse if we have a single line
            new(args.last.nil? ? args.first : args.join('='))
          end
        end

        attr_reader :src

        def initialize(src)
          @src = src
        end

        def key
          strip_secure(src)
        end

        def value
          nil
        end

        def echoize
          if travis?
            false
          elsif secure?
            strip_secure(hide_value(src))
          else
            src
          end
        end

        def travis?
          src =~ /^TRAVIS_/
        end

        def secure?
          src =~ /^SECURE /
        end

        private

          def hide_value(string)
            [string.split('=').first, '[secure]'].join('=')
          end

          def strip_secure(string)
            string.gsub('SECURE ', '')
          end
      end
    end
  end
end
