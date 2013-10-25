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

        def cache_slug
          # ruby version is added by RVM]
          super << "--gemfile-" << config[:gemfile].to_s
        end

        def use_directory_cache?
          super or data.cache?(:bundler)
        end

        def setup
          super
          setup_bundler
        end

        def announce
          super
          cmd 'gem --version'
        end

        def install
          gemfile? do |sh|
            sh.if "-f #{config[:gemfile]}.lock" do |sub|
              directory_cache.add(sub, bundler_path) if data.cache? :bundler
              sub.cmd bundler_command("--deployment"), fold: 'install', retry: true
            end

            sh.else do |sub|
              # cache bundler if it has been explicitely enabled
              directory_cache.add(sub, bundler_path) if data.cache? :bundler, false
              sub.cmd bundler_command, fold: 'install', retry: true
            end
          end
        end

        def script
          gemfile? then: 'bundle exec rake', else: 'rake'
        end

        def prepare_cache
          "bundle clean" if bundler_path
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
            args = bundler_args if bundler_args
            args = [args].flatten << "--path=#{bundler_path}" if data.cache?(:bundler) and !bundler_args_path
            ["bundle install", *args].compact.join(" ")
          end

          def bundler_args
            config[:bundler_args]
          end

          def setup_bundler
            gemfile? do |sh|
              set 'BUNDLE_GEMFILE', "$PWD/#{config[:gemfile]}"
            end
          end

          def gemfile?(*args, &block)
            self.if "-f #{config[:gemfile]}", *args, &block
          end

          def uses_java?
            uses_jdk?
          end
      end
    end
  end
end
