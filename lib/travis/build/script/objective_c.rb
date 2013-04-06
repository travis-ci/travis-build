module Travis
  module Build
    class Script
      class ObjectiveC < Script
        def announce
          super
          cmd 'xcodebuild -version -sdk', fold: 'announce'
        end

        def install
          self.if uses_cocoapods?, then: 'pod install', fold: 'install'
          self.elif uses_rubymotion?, then: 'bundle install', fold: 'install'
        end

        def script
          self.if uses_rubymotion?, then: 'bundle exec rake spec'
          self.else '/Users/travis/travis-utils/osx-cibuild.sh'
        end

        private

        def uses_cocoapods?(*args)
          '-f Podfile'
        end

        def uses_rubymotion?(*args)
          '-f Rakefile && "$(cat Rakefile)" =~ "require \'motion/project\'"'
        end
      end
    end
  end
end
