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
          gemfile? then: "bundle install #{config[:bundler_args]}", fold: 'install'
        end

        def script
          gemfile? then: 'bundle exec rake', else: 'rake'
        end

        private

          def setup_bundler
            gemfile? do |sh|
              set 'BUNDLE_GEMFILE', "$PWD/#{config[:gemfile]}"
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
