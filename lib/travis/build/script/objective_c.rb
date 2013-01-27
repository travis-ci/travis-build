module Travis
  module Build
    class Script
      class ObjectiveC < Script
        def announce
          super
          cmd 'xcodebuild -version -sdk'
        end

        def setup
          super
          # TODO: Uncomment this once the template has a working xcodebuild wrapper
          # raw template 'xcode.sh'
        end

        def install
          uses_cocoapods? 'pod install'
        end

        def script
          workspace = config[:xcode_workspace] ? "-workspace #{config[:xcode_workspace]}.xcworkspace" : ''
          cmd "xcodebuild #{workspace} -scheme #{config[:xcode_scheme]} clean test"
        end

        private

        def uses_cocoapods?(*args)
          sh_if '-f Podfile', *args
        end
      end
    end
  end
end
