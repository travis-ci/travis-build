require 'hashr'

module Travis
  class Build
    module Job
      class Test
        class Ruby < Test
          include JdkSwitcher

          class Config < Hashr
            define :rvm => 'default', :gemfile => 'Gemfile'
          end

          def setup
            super

            setup_jdk if needs_jdk?

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
              @uses_bundler ||= shell.file_exists?(config.gemfile)
            end

            def announce_ruby
              shell.execute("ruby --version")
              shell.execute("gem --version")
            end

            def export_environment_variables
              export_jdk_environment_variables if needs_jdk?
              shell.export_line("TRAVIS_RUBY_VERSION=#{config.rvm}")
            end

            def needs_jdk?
              config[:rvm] =~ /jruby/i and !!config[:jdk]
            end
        end
      end
    end
  end
end
