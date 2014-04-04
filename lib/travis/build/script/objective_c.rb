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

        def export
          super

          set 'TRAVIS_XCODE_SDK', config[:xcode_sdk], echo: false
          set 'TRAVIS_XCODE_SCHEME', config[:xcode_scheme], echo: false
          set 'TRAVIS_XCODE_PROJECT', config[:xcode_project], echo: false
          set 'TRAVIS_XCODE_WORKSPACE', config[:xcode_workspace], echo: false
        end

        def setup
          super

          cmd "echo '#!/bin/bash\n# no-op' > /usr/local/bin/actool", echo: false
          cmd "chmod +x /usr/local/bin/actool", echo: false

          cmd "osascript -e 'set simpath to \"/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Applications/iPhone Simulator.app/Contents/MacOS/iPhone Simulator\" as POSIX file' -e 'tell application \"Finder\"' -e 'open simpath' -e 'end tell'"
        end

        def install
          has_gemfile? then: 'bundle install', fold: 'install.bundler', retry: true
          has_podfile? then: 'pod install', fold: 'install.cocoapods', retry: true
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
