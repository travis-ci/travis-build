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
            unless bundler_args.nil?
              sh.cmd "bundle install #{bundler_args}", fold: 'install', retry: true
            else
              sh.if "-f #{config[:gemfile]}.lock", then: 'bundle install --deployment', else: 'bundle install', fold: 'install', retry: true
            end
          end
        end

        def script
          gemfile? then: 'bundle exec rake', else: 'rake'
        end

        private

          def bundler_args
            config[:bundler_args]
          end

          def setup_bundler
            gemfile? do |sh|
              set 'BUNDLE_GEMFILE', "$PWD/#{config[:gemfile]}"
              cmd 'gem query --local | grep bundler >/dev/null || gem install bundler'
            end
          end

          def gemfile?(*args, &block)
            self.if "-f #{config[:gemfile]}", *args, &block
          end

          def uses_java?
            config[:rvm] =~ /jruby/i
          end

          def uses_jdk?
            uses_java? && super
          end
      end
    end
  end
end
