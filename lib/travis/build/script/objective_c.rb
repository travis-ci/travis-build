module Travis
  module Build
    class Script
      class ObjectiveC < Script
        def announce
          super
          cmd 'xcodebuild -version -sdk', fold: 'announce'
        end

        def install
          uses_cocoapods? 'pod install', fold: 'install'
        end

        def script
          '~/travis-utils/osx-cibuild.sh'
        end

        private

        def uses_cocoapods?(*args)
          self.if '-f Podfile', *args
        end
      end
    end
  end
end
