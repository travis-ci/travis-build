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

          if user_provided_gemfile
            sh.if user_provided_gemfile? do
              sh.echo "Using #{user_provided_gemfile}"
            end
            sh.else do
              sh.failure "#{user_provided_gemfile} not found, cannot continue"
            end
          end

          sh.if gemfile? do
            sh.export 'BUNDLE_GEMFILE', "$PWD/#{config[:gemfile]}"
          end
        end

        def announce
          super
          sh.cmd 'bundle --version'
        end

        def setup_cache
          return unless use_directory_cache?

          sh.if gemfile? do
            sh.if gemfile_lock? do
              sh.newline
              if data.cache?(:bundler)
                sh.fold 'cache.bundler' do
                  directory_cache.add(bundler_path(false))
                end
              end
            end
            sh.else do
              # Cache bundler if it has been explicitly enabled
              sh.newline
              if data.cache?(:bundler, false)
                sh.fold 'cache.bundler' do
                  directory_cache.add(bundler_path(false))
                end
              end
            end
          end
        end

        def install
          sh.if gemfile? do
            sh.if gemfile_lock? do
              sh.if '-e vendor/cache' do
                sh.if '$(du -s vendor/cache | cut -f 1) -eq 0' do
                  sh.cmd 'rm -rf vendor/cache', echo: false, timing: false, assert: false
                end
              end
              sh.cmd bundler_install("--deployment"), fold: "install.bundler", retry: true
            end
            sh.else do
              sh.cmd bundler_install, fold: "install.bundler", retry: true
            end
          end
          sh.else do
            sh.echo 'No Gemfile found, skipping bundle install'
          end
          sh.newline
        end

        def prepare_cache
          sh.cmd 'bundle clean', assert: false, timing: false if bundler_path and data.cache?(:bundler)
        end

        def cache_slug
          super << '--gemfile-' << config[:gemfile].to_s
        end

        private

          def user_provided_gemfile
            raw_data[:config] && raw_data[:config][:gemfile]
          end

          def user_provided_gemfile?
            "-f #{user_provided_gemfile}"
          end

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
