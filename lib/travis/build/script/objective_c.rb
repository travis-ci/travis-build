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
        end

        def setup
          super

          if config[:xcode_sdk]
            set 'XCODEBUILD_SETTINGS', "-sdk #{config[:xcode_sdk]} TEST_AFTER_BUILD=YES".shellescape
          end
        end

        def install
          has_podfile? then: 'pod install', fold: 'install.cocoapods'
          has_gemfile? then: 'bundle install', fold: 'install.bundler'
        end

        def script
          uses_rubymotion? then: 'bundle exec rake spec'
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
          self.if '-f Rakefile && "$(cat Rakefile)" =~ require\ [\\"\\\']motion/project', *args
        end

        def scheme
          " #{config[:xcode_scheme]}" if config[:xcode_scheme]
        end
      end
    end
  end
end
