module Travis
  class Build
    module Job
      class Test
        class Clojure < Test
          class Config < Hashr
            define :install => 'lein deps', :script  => 'lein test'
          end
        end
      end
    end
  end
end
