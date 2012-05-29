module Travis
  class Build
    module Job
      class Test
        class Clojure < Test
          include JdkSwitcher

          class Config < Hashr
            define :lein => "lein", :jdk => 'openjdk7'
          end

          def setup
            super
            setup_jdk
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

            def export_environment_variables
              export_jdk_environment_variables
            end
        end
      end
    end
  end
end
