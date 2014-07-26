module Travis
  module Build
    class Script
      class Ruby < Script
        DEFAULTS = {
          rvm:     'default',
          gemfile: 'Gemfile'
        }

        include Jdk
        include RVM

        DEFAULT_BUNDLER_ARGS = "--jobs=3 --retry=3"

        def setup
          super

          sh.if "-f #{config[:gemfile]}" do
            set 'BUNDLE_GEMFILE', "$PWD/#{config[:gemfile]}", echo: true
          end
        end

        def announce
          cmd 'ruby --version', echo: true, timing: false
          super
          cmd 'gem --version', echo: true, timing: false
          cmd 'bundle --version', echo: true, timing: false
        end

        def install
          fold 'install' do
            sh.if "-f #{config[:gemfile]} && -f #{config[:gemfile]}.lock" do
              directory_cache.add(sh, bundler_path) if data.cache? :bundler
              sh.cmd bundler_command("--deployment"), assert: true, echo: true, retry: true
            end
            sh.elif "-f #{config[:gemfile]}" do
              directory_cache.add(sh, bundler_path) if data.cache? :bundler, false
              sh.cmd bundler_command, assert: true, echo: true, retry: true
            end
          end
        end

        def script
          sh.if "-f #{config[:gemfile]}" do
            sh.cmd 'bundle exec rake', echo: true
          end
          sh.else do
            sh.cmd 'rake', echo: true
          end
        end

        def prepare_cache
          sh.cmd 'bundle clean' if bundler_path
        end

        def cache_slug
          super << "--gemfile-" << config[:gemfile].to_s # ruby version is added by RVM
        end

        def use_directory_cache?
          super or data.cache?(:bundler)
        end

        private

          def bundler_args_path
            args = Array(bundler_args).join(" ")
            path = args[/--path[= ](\S+)/, 1]
            path ||= 'vendor/bundle' if args.include?('--deployment')
            path
          end

          def bundler_path
            bundler_args_path || "${BUNDLE_PATH:-vendor/bundle}"
          end

          def bundler_command(args = nil)
            args = bundler_args ? bundler_args : [DEFAULT_BUNDLER_ARGS, args].compact
            args = [args].flatten << "--path=#{bundler_path}" if data.cache?(:bundler) and !bundler_args_path
            ["bundle install", *args].compact.join(" ")
          end

          def bundler_args
            config[:bundler_args]
          end

          def uses_java?
            uses_jdk?
          end
      end
    end
  end
end
