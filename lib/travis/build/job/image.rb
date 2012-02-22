module Travis
  class Build
    module Job
      class Image
        include Logging

        log_header { "#{Thread.current[:log_header]}:job:image" }

        attr_reader :config

        def initialize(config)
          @config = config
        end

        def run
          build
          {}
        end

        protected

          def build
          end
      end
    end
  end
end

