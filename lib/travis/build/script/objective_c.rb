require 'shellwords'

module Travis
  module Build
    class Script
      class ObjectiveC < Script
        DEFAULTS = {
          rvm:     'default',
          gemfile: 'Gemfile'
        }

        include RVM
        include Bundler

        def use_directory_cache?
          super || data.cache?(:cocoapods)
        end

        def announce
          super
          cmd 'xcodebuild -version -sdk', fold: 'announce'
          uses_rubymotion? then: 'motion --version'
          podfile? then: 'pod --version'
        end

        def export
          super

          set 'TRAVIS_XCODE_SDK', config[:xcode_sdk].to_s.shellescape, echo: false
          set 'TRAVIS_XCODE_SCHEME', config[:xcode_scheme].to_s.shellescape, echo: false
          set 'TRAVIS_XCODE_PROJECT', config[:xcode_project].to_s.shellescape, echo: false
          set 'TRAVIS_XCODE_WORKSPACE', config[:xcode_workspace].to_s.shellescape, echo: false
        end

        def setup
          super

          cmd "echo '#!/bin/bash\n# no-op' > /usr/local/bin/actool", echo: false
          cmd "chmod +x /usr/local/bin/actool", echo: false
          cmd "osascript -e 'set simpath to \"/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Applications/iPhone Simulator.app/Contents/MacOS/iPhone Simulator\" as POSIX file' -e 'tell application \"Finder\"' -e 'open simpath' -e 'end tell'"
        end

        def install
          super

          podfile? do |sh|
            # cache cocoapods if it has been explicitely enabled
            directory_cache.add(sh, 'Pods') if data.cache? :cocoapods, false
            sh.cmd 'pod install', fold: 'install.cocoapods', retry: true
          end
        end

        def script
          uses_rubymotion?(with_bundler: true, then: 'bundle exec rake spec')
          uses_rubymotion?(elif: true, then: 'rake spec')

          self.else do |script|
            if config[:xcode_scheme] && (config[:xcode_project] || config[:xcode_workspace])
              script.cmd "xctool #{xctool_args} build test"
            else
              script.cmd "echo -e \"\\033[33;1mWARNING:\\033[33m Using Objective-C testing without specifying a scheme and either a workspace or a project is deprecated.\"", echo: false
              script.cmd "echo \"  Check out our documentation for more information: http://about.travis-ci.org/docs/user/languages/objective-c/\"", echo: false
            end
          end
        end

        private

        def podfile?(*args, &block)
          self.if "-f Podfile", *args, &block
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

        def xctool_args
          config[:xctool_args].to_s.tap do |xctool_args|
            %w[project workspace scheme sdk].each do |var|
              xctool_args << " -#{var} #{config[:"xcode_#{var}"].to_s.shellescape}" if config[:"xcode_#{var}"]
            end
          end.strip
        end
      end
    end
  end
end
