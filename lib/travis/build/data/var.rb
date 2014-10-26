module Travis
  module Build
    class Data
      class Var
        PATTERN = /(?:SECURE )?([\w]+)=(("|')(.*?)(\3)|\$\(.*?\)|[^"' ]+)/

        class << self
          def create(*args)
            if args.size == 1
              parse(args.first).map { |key, value| Var.new(key, value) }
            else
              [Var.new(*args)]
            end
          end

          def parse(line)
            secure = line =~ /^SECURE /
            line.scan(PATTERN).map { |match| [(secure ? "SECURE #{match[0]}" : match[0]), match[1]] }
          end
        end

        attr_reader :value

        def initialize(key, value, secure = nil)
          @key = key.to_s
          @value = value.to_s
          @secure = secure
        end

        def key
          strip_secure(@key)
        end

        def to_s
          if travis?
            false
          elsif secure?
            "export #{[key, '[secure]'].join('=')}"
          else
            "export #{[key, value].join('=')}"
          end
        end

        def travis?
          @key =~ /^TRAVIS_/
        end

        def secure?
          !!(@secure.nil? ? @key =~ /^SECURE / : @secure)
        end

        private

          def strip_secure(string)
            string.gsub('SECURE ', '')
          end
      end
    end
  end
end
