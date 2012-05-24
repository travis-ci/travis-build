require 'travis/build/job/test/jvm_language'

module Travis
  class Build
    module Job
      class Test
        # JRuby makes "Java" a reserved word so we cannot name our subclass like that
        class PureJava < JvmLanguage
          #class Config < Hashr
          #end

          protected

            def setup_java
              shell.execute("sudo jdk-switcher use #{config.java}")
            end
            assert :setup_java

            def announce_java
              shell.execute("java -version")
              shell.execute("javac -version")
            end
        end
      end
    end
  end
end
