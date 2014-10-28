module Travis
  module Build
    class Script
      module Bundler
        DEFAULT_BUNDLER_ARGS = "--jobs=3 --retry=3"

        def use_directory_cache?
          super || data.cache?(:bundler)
        end

        def setup
          super

          sh.if gemfile? do
            sh.export 'BUNDLE_GEMFILE', "$PWD/#{config[:gemfile]}"
          end
        end

        def announce
          super
          sh.cmd 'bundle --version', timing: false
        end

        def install
          sh.if gemfile_lock? do
            directory_cache.add(sh, bundler_path) if data.cache?(:bundler)
            sh.cmd bundler_command("--deployment"), fold: "install.bundler", retry: true
          end
          sh.elif gemfile? do
            # Cache bundler if it has been explicitly enabled
            directory_cache.add(sh, bundler_path) if data.cache?(:bundler, false)
            sh.cmd bundler_command, fold: "install.bundler", retry: true
          end
        end

        def prepare_cache
          cmd('bundle clean') if bundler_path and data.cache?(:bundler)
        end

        def cache_slug
          super << '--gemfile-' << config[:gemfile].to_s
        end

        private

          def gemfile?
            "-f #{config[:gemfile]}"
          end

          def gemfile_lock?
            "-f #{config[:gemfile]} && -f #{config[:gemfile]}.lock"
          end

          def bundler_args_path
            args = Array(bundler_args).join(" ")
            path = args[/--path[= ](\S+)/, 1]
            path ||= 'vendor/bundle' if args.include?('--deployment')
            path
          end

          def bundler_path
            bundler_args_path || '${BUNDLE_PATH:-vendor/bundle}'
          end

          def bundler_command(args = nil)
            args = bundler_args || [DEFAULT_BUNDLER_ARGS, args].compact
            args = [args].flatten << "--path=#{bundler_path}" if data.cache?(:bundler) && !bundler_args_path
            ['bundle install', *args].compact.join(' ')
          end

          def bundler_args
            config[:bundler_args]
          end
      end
    end
  end
end
