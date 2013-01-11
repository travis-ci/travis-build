module Travis
  module Build
    class Data
      class Var
        PATTERN = /((?:SECURE )?[\w]+)=(("|')(.+?)(\3)|[^"' ]+)/

        class << self
          def create(*args)
            if args.size == 1
              parse(args.first).map { |key, value| Var.new(key, value) }
            else
              [Var.new(*args)]
            end
          end

          def parse(line)
            line.scan(PATTERN).map { |match| [match[0], match[3] || match[1]] }
          end
        end

        def initialize(key, value)
          @key = key.to_s
          @value = value.to_s
        end

        def key
          strip_secure(@key)
        end

        def value
          escape(@value)
        end

        def echoize
          if travis?
            false
          elsif secure?
            "export #{[key, '[secure]'].join('=')}"
          else
            "export #{[key, escape(@value)].join('=')}"
          end
        end

        def travis?
          @key =~ /^TRAVIS_/
        end

        def secure?
          @key =~ /^SECURE /
        end

        private

          def strip_secure(string)
            string.gsub('SECURE ', '')
          end

          def escape(string)
            string # TODO
          end
      end
    end
  end
end
