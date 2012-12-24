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
          set 'TRAVIS_RUBY_VERSION', config[:rvm]
          export_jdk if needs_jdk?
        end

        def setup
          super
          setup_jdk if needs_jdk?
          setup_ruby
          setup_bundler
        end

        def announce
          super
          cmd 'ruby --version'
          cmd 'gem --version'
        end

        def install
          gemfile? then: "bundle install #{config[:bundler_args]}"
        end

        def script
          gemfile? then: 'bundle exec rake', else: 'rake'
        end

        private

          def setup_ruby
            cmd "rvm use #{config[:rvm]}"
          end

          def setup_bundler
            gemfile? do |sh|
              set 'BUNDLE_GEMFILE', "$pwd/#{config[:gemfile]}"
            end
          end

          def gemfile?(*args, &block)
            sh_if "-f #{config[:gemfile]}", *args, &block
          end

          def needs_jdk?
            config[:rvm] =~ /jruby/i and !!config[:jdk]
          end
      end
    end
  end
end
