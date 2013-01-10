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
          update_rvm
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

          def update_rvm
            echo "Updating RVM, this should just take a sec"
            echo "$ rvm get head"
            cmd "rvm get head > /dev/null", echo: false, log: false
          end

          def setup_ruby
            ruby_version = data[:rvm].gsub(/-(1[89])mode$/, '-d\1')
            cmd "typeset -f rvm >/dev/null 2>&1 || source $(dirname $(dirname $(which rvm)))/scripts/rvm", echo: false
            cmd "rvm use #{ruby_version} --install --binary"
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
