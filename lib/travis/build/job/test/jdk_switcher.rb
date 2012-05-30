module Travis
  class Build
    module Job
      class Test
        module JdkSwitcher
          extend Assertions

          def setup_jdk
            setup_jdk_switcher
            announce_jdk
          end

          protected

            def setup_jdk_switcher
              shell.execute("jdk_switcher use #{config.jdk}")
            end
            assert :setup_jdk_switcher

            def announce_jdk
              shell.execute("java -version")
              shell.execute("javac -version")
            end

            def export_jdk_environment_variables
              shell.export_line("TRAVIS_JDK_VERSION=#{config.jdk}")
            end
        end
      end
    end
  end
end
