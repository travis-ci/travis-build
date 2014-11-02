module Travis
  module Build
    class Env
      class Var
        PATTERN = /(?:SECURE )?([\w]+)=(("|')(.*?)(\3)|\$\(.*?\)|[^"' ]+)/

        class << self
          def create(*args)
            options = args.last.is_a?(Hash) ? args.pop : {}
            if args.size == 1
              parse(args.first).map { |key, value| Var.new(key, value, options) }
            else
              [Var.new(*args, options)]
            end
          end

          def parse(line)
            secure = line =~ /^SECURE /
            line.scan(PATTERN).map { |match| [(secure ? "SECURE #{match[0]}" : match[0]), match[1]] }
          end
        end

        attr_reader :value, :type

        def initialize(key, value, options = {})
          @key = key.to_s
          @value = value.to_s
          @secure = options[:secure]
          @type = options[:type]
        end

        def key
          strip_secure(@key)
        end

        def echo?
          type != :builtin
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
