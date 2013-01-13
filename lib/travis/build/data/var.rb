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
            line.scan(PATTERN).map { |match| [match[0], match[1]] }
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
          decrypt? ? add_decrypt(@value) : @value
        end

        def to_s
          if travis?
            false
          elsif secure?
            "export #{[key, '[secure]'].join('=')}"
          else
            "export #{[key, @value].join('=')}"
          end
        end

        def travis?
          @key =~ /^TRAVIS_/
        end

        def secure?
          @key =~ /^!?SECURE /
        end

        def decrypt?
          @key =~ /^!SECURE /
        end

        private

          def strip_secure(string)
            string.gsub('SECURE ', '')
          end

          def add_decrypt(string)
            "$(travis_decrypt '#{string.gsub("\n", '')}')"
          end
      end
    end
  end
end
