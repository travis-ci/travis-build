require 'travis/build/script/shared/bundler'
require 'travis/build/script/shared/jdk'
require 'travis/build/script/shared/rvm'

module Travis
  module Build
    class Script
      class Ruby < Script
        DEFAULTS = {
          rvm:     'default',
          gemfile: 'Gemfile'
        }

        include Bundler, RVM, Jdk

        def announce
          sh.fold 'ruby.versions' do
            super
            sh.cmd 'gem --version'
          end
          sh.newline
        end

        def script
          sh.if "-f #{config[:gemfile]}" do
            sh.cmd 'bundle exec rake'
          end
          sh.else do
            sh.cmd 'rake'
          end
        end

        private

          def uses_java?
            ruby_version.include?('jruby')
          end
      end
    end
  end
end
