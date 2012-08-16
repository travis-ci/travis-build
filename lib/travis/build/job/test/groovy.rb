require 'travis/build/job/test/jvm_language'

module Travis
  class Build
    module Job
      class Test
        class Groovy < JvmLanguage
          log_header { [Thread.current[:log_header], "build:job:test:groovy"].join(':') }

          #class Config < Hashr
          #end

          # this builder completely inherits all the logic from the JvmLanguage one. MK.
        end
      end
    end
  end
end
