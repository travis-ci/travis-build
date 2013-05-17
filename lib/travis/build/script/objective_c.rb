require 'shellwords'

module Travis
  module Build
    class Script
      class ObjectiveC < Script
        DEFAULTS = {
          rvm:     'default'
        }

        include RVM

        def announce
          super
          cmd 'xcodebuild -version -sdk', fold: 'announce'
          uses_rubymotion? then: 'motion --version'
          has_podfile? then: 'pod --version'
        end

        def setup
          super

          if config[:xcode_sdk]
            set 'XCODEBUILD_SETTINGS', "-sdk #{config[:xcode_sdk]} TEST_AFTER_BUILD=YES".shellescape
          end
        end

        def install
          has_podfile? then: 'pod install', fold: 'install.cocoapods', retry: true
          has_gemfile? then: 'bundle install', fold: 'install.bundler', retry: true
        end

        def script
          uses_rubymotion?(with_bundler: true, then: 'bundle exec rake spec')
          uses_rubymotion?(elif: true, then: 'rake spec')
          self.else "/Users/travis/travis-utils/osx-cibuild.sh#{scheme}"
        end

        private

        def has_podfile?(*args)
          self.if '-f Podfile', *args
        end

        def has_gemfile?(*args)
          self.if '-f Gemfile', *args
        end

        def uses_rubymotion?(*args)
          conditional = '-f Rakefile && "$(cat Rakefile)" =~ require\ [\\"\\\']motion/project'
          conditional << ' && -f Gemfile' if args.first && args.first.is_a?(Hash) && args.first.delete(:with_bundler)
          if args.first && args.first.is_a?(Hash) && args.first.delete(:elif)
            self.elif conditional, *args
          else
            self.if conditional, *args
          end
        end

        def scheme
          " #{config[:xcode_scheme]}" if config[:xcode_scheme]
        end
      end
    end
  end
end
