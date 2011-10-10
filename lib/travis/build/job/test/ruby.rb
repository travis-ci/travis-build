require 'hashr'
require 'active_support/memoizable'

module Travis
  class Build
    module Job
      class Test
        class Ruby < Test
          class Config < Hashr
            define :rvm => 'default', :gemfile => 'Gemfile'
          end

          extend ActiveSupport::Memoizable

          def setup
            setup_ruby
            setup_bundler if gemfile?
          end

          def install
            bundle_install if gemfile?
          end

          protected

            def setup_ruby
              output = shell.evaluate("rvm use #{config.rvm}", :echo => true)
              output !~ /ERROR|WARN/
            end
            assert :setup_ruby

            def setup_bundler
              shell.export('BUNDLE_GEMFILE', "#{shell.cwd}/#{config.gemfile}")
            end

            def gemfile?
              shell.file_exists?(config.gemfile)
            end
            memoize :gemfile?

            def bundle_install
              shell.execute("bundle install #{config.bundler_args}".strip, :timeout => :install)
            end
            assert :bundle_install

            def script
              if config.script?
                config.script
              elsif gemfile?
                'bundle exec rake'
              else
                'rake'
              end
            end
        end
      end
    end
  end
end
