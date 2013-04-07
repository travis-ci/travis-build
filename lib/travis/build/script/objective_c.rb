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

        def install
          has_podfile? then: 'pod install', fold: 'install.cocoapods'
          has_gemfile? then: 'bundle install', fold: 'install.bundler'
        end

        def script
          self.if uses_rubymotion?, then: 'bundle exec rake spec'
          self.else '/Users/travis/travis-utils/osx-cibuild.sh'
        end

        private

        def has_podfile?(*args)
          self.if '-f Podfile', *args
        end

        def has_gemfile?(*args)
          self.if '-f Gemfile', *args
        end

        def uses_rubymotion?(*args)
          '-f Rakefile && "$(cat Rakefile)" =~ "require \'motion/project\'"'
        end
      end
    end
  end
end
