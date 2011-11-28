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
            setup_bundler if gemfile?
          end

          def install
            "bundle install #{config.bundler_args}".strip if gemfile?
          end

          def script
            gemfile? ? 'bundle exec rake' : 'rake'
          end

          protected

            def setup_ruby
              output = shell.evaluate("rvm use #{config.rvm}", :echo => true)
              output !~ /ERROR|WARN/
            end
            assert :setup_ruby

            def setup_bundler
              shell.export_line("BUNDLE_GEMFILE=#{shell.cwd}/#{config.gemfile}")
            end

            def gemfile?
              shell.file_exists?(config.gemfile)
            end
            memoize :gemfile?

            def announce_ruby
              shell.execute("ruby --version")
            end
        end
      end
    end
  end
end
