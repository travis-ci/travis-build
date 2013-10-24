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

          cmd "echo '#!/bin/bash\n# no-op' > /usr/local/bin/actool", echo: false
          cmd "chmod +x /usr/local/bin/actool", echo: false
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
              script.cmd "/Users/travis/travis-utils/osx-cibuild.sh"
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
              xctool_args << " -#{var} #{config[:"xcode_#{var}"].shellescape}" if config[:"xcode_#{var}"]
            end
          end.strip
        end
      end
    end
  end
end
