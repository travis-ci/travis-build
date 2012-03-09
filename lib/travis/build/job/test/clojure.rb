require 'travis/build/job/test/jvm_language'

module Travis
  class Build
    module Job
      class Test
        class Clojure < Test
          class Config < Hashr
            define :lein => "lein"
          end

          def setup
            super
            announce_leiningen
          end

          def install
            "#{leiningen} deps"
          end

          def script
            "#{leiningen} test"
          end

          def uses_leiningen?
            @uses_leiningen ||= shell.file_exists?('project.clj')
          end

          protected

            def leiningen
              config.lein
            end

            def announce_leiningen
              shell.execute("#{leiningen} version")
            end
        end
      end
    end
  end
end
