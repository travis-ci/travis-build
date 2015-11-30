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
          setup_cache
        end

        def announce
          super
          sh.cmd 'bundle --version'
        end

        def setup_cache
          sh.if gemfile? do
            sh.if gemfile_lock? do
              directory_cache.add(bundler_path(false)) if data.cache?(:bundler)
            end
            sh.else do
              # Cache bundler if it has been explicitly enabled
              directory_cache.add(bundler_path(false)) if data.cache?(:bundler, false)
            end
          end
        end

        def install
          sh.if gemfile? do
            sh.export 'BUNDLE_GEMFILE', "$PWD/#{config[:gemfile]}"
            sh.if gemfile_lock? do
              sh.cmd bundler_install("--deployment"), fold: "install.bundler", retry: true
            end
            sh.else do
              # Cache bundler if it has been explicitly enabled
              sh.cmd bundler_install, fold: "install.bundler", retry: true
            end
          end
        end

        def prepare_cache
          sh.cmd 'bundle clean', assert: false, timing: false if bundler_path and data.cache?(:bundler)
        end

        def cache_slug
          super << '--gemfile-' << config[:gemfile].to_s
        end

        private

          def gemfile?
            "-f ${BUNDLE_GEMFILE:-#{config[:gemfile]}}"
          end

          def gemfile_lock?
            "-f ${BUNDLE_GEMFILE:-#{config[:gemfile]}}.lock"
          end

          def gemfile_path(*path)
            base_dir = File.dirname(config[:gemfile])
            File.join(base_dir, *path)
          end

          def bundler_args_path
            args = Array(bundler_args).join(" ")
            path = args[/--path[= ](\S+)/, 1]
            path ||= 'vendor/bundle' if args.include?('--deployment')
            path
          end

          def bundler_default_path(relative_to_gemfile)
            default = relative_to_gemfile ? 'vendor/bundle' : gemfile_path('vendor/bundle')
            "${BUNDLE_PATH:-#{default}}"
          end

          def bundler_path_relative_to_gemfile
            @bundler_path_relative_to_gemfile ||= bundler_args_path || bundler_default_path(true)
          end

          def bundler_path_relative_to_project
            @bundler_path_relative_to_project ||= bundler_args_path ? gemfile_path(bundler_args_path) : bundler_default_path(false)
          end

          def bundler_path(relative_to_gemfile = false)
            relative_to_gemfile ? bundler_path_relative_to_gemfile : bundler_path_relative_to_project
          end

          def bundler_install(args = nil)
            args = bundler_args || [DEFAULT_BUNDLER_ARGS, args].compact
            args = [args].flatten << "--path=#{bundler_path(true)}" if data.cache?(:bundler) && !bundler_args_path
            ['bundle install', *args].compact.join(' ')
          end

          def bundler_args
            config[:bundler_args]
          end
      end
    end
  end
end
