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
            announce_ruby
            setup_bundler if uses_bundler?
          end

          def install
            "bundle install #{config.bundler_args}".strip if uses_bundler?
          end

          def script
            uses_bundler? ? 'bundle exec rake' : 'rake'
          end

          protected

            def setup_ruby
              shell.execute("rvm use #{config.rvm}", :echo => true)
            end
            assert :setup_ruby

            def setup_bundler
              shell.export_line("BUNDLE_GEMFILE=#{shell.cwd}/#{config.gemfile}")
            end

            def uses_bundler?
              shell.file_exists?(config.gemfile)
            end
            memoize :uses_bundler?

            def announce_ruby
              shell.execute("ruby --version")
            end
        end
      end
    end
  end
end
