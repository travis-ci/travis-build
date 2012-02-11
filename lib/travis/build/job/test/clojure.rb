require 'travis/build/job/test/jvm_language'

module Travis
  class Build
    module Job
      class Test
        class Clojure < Test
          class Config < Hashr
            define :install => 'lein deps', :script  => 'lein test'
          end

          def setup
            super

            announce_leiningen
          end

          def uses_leiningen?
            @uses_leiningen ||= shell.file_exists?('project.clj')
          end

          protected

          def announce_leiningen
            shell.execute("lein version")
          end
        end
      end
    end
  end
end
