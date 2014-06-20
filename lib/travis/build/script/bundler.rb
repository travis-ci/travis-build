module Travis
  module Build
    class Script
      module Bundler
        DEFAULT_BUNDLER_ARGS = "--jobs=3 --retry=3"

        def cache_slug
          super << "--gemfile-" << config[:gemfile].to_s
        end

        def use_directory_cache?
          super || data.cache?(:bundler)
        end

        def setup
          super

          gemfile? do |sh|
            sh.set "BUNDLE_GEMFILE", "$PWD/#{config[:gemfile]}"
          end
        end

        def announce
          super
          cmd "bundle --version"
        end

        def install
          super
          gemfile? do |sh|
            sh.if "-f #{config[:gemfile]}.lock" do |sub|
              directory_cache.add(sub, bundler_path) if data.cache?(:bundler)
              sub.cmd bundler_command("--deployment"), fold: "install", retry: true
            end

            sh.else do |sub|
              # Cache bundler if it has been explicitly enabled
              directory_cache.add(sub, bundler_path) if data.cache?(:bundler, false)
              sub.cmd bundler_command, fold: "install", retry: true
            end
          end
        end

        def prepare_cache
          cmd("bundle clean") if bundler_path
        end

        private

        def gemfile?(*args, &block)
          self.if "-f #{config[:gemfile]}", *args, &block
        end

        def bundler_args_path
          args = Array(bundler_args).join(" ")
          path = args[/--path[= ](\S+)/, 1]
          path ||= "vendor/bundle" if args.include?("--deployment")
          path
        end

        def bundler_path
          bundler_args_path || "${BUNDLE_PATH:-vendor/bundle}"
        end

        def bundler_command(args = nil)
          args = bundler_args || [DEFAULT_BUNDLER_ARGS, args].compact
          args = [args].flatten << "--path=#{bundler_path}" if data.cache?(:bundler) && !bundler_args_path
          ["bundle install", *args].compact.join(" ")
        end

        def bundler_args
          config[:bundler_args]
        end
      end
    end
  end
end
