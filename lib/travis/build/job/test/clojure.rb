module Travis
  module Build
    module Job
      class Test
        class Clojure < Test
          class Config < Hashr
          end

          def install
            shell.execute("lein deps", :timeout => :install)
          end
          assert :install

          protected

            def script
              if config.script?
                config.script
              else
                'lein test'
              end
            end
        end
      end
    end
  end
end

