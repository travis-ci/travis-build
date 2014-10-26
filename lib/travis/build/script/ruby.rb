module Travis
  module Build
    class Script
      class Ruby < Script
        DEFAULTS = {
          rvm:     'default',
          gemfile: 'Gemfile'
        }

        include Jdk, RVM, Bundler

        def announce
          super
          sh.cmd 'gem --version', timing: false
        end

        def script
          gemfile? then: 'bundle exec rake', else: 'rake'
        end

        private

        def uses_java?
          uses_jdk?
        end
      end
    end
  end
end
