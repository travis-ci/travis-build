module Travis
  module Build
    module Job
      class Test
        class Closure < Test
          class Config < Hashr
            define :rvm => 'default', :gemfile => 'Gemfile'
          end

          def setup
            super
            setup_bundler if gemfile?
          end

          def install
            bundle_install if gemfile?
          end

          protected

            def setup_ruby
              shell.execute("rvm use #{config.rvm}")
            end

            def setup_bundler
              shell.execute("export BUNDLE_GEMFILE=#{cwd}/#{config.gemfile}")
            end

            def gemfile?
              shell.file_exists?(config.gemfile)
            end

            def bundle_install
              shell.execute("bundle install #{config.bundler_args}".strip, :timeout => :install)
            end
            assert :bundle_install

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

