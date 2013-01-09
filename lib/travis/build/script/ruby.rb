module Travis
  module Build
    class Script
      class Ruby < Script
        DEFAULTS = {
          rvm:     'default',
          gemfile: 'Gemfile'
        }

        include Jdk

        def export
          super
          set 'TRAVIS_RUBY_VERSION', data[:rvm]
        end

        def setup
          super
          setup_ruby
          setup_bundler
        end

        def announce
          super
          cmd 'ruby --version'
          cmd 'gem --version'
        end

        def install
          gemfile? then: "bundle install #{data[:bundler_args]}"
        end

        def script
          gemfile? then: 'bundle exec rake', else: 'rake'
        end

        private

          def setup_ruby
            cmd "rvm use #{data[:rvm]}"
          end

          def setup_bundler
            gemfile? do |sh|
              set 'BUNDLE_GEMFILE', "$pwd/#{data[:gemfile]}"
            end
          end

          def gemfile?(*args, &block)
            sh_if "-f #{data[:gemfile]}", *args, &block
          end

          def uses_java?
            data[:rvm] =~ /jruby/i
          end

          def uses_jdk?
            uses_java? && super
          end
      end
    end
  end
end
