require 'shellwords'

module Travis
  module Build
    class Script
      class ObjectiveC < Script
        DEFAULTS = {
          rvm: 'default'
        }

        include RVM

        def announce
          super

          sh.fold 'announce' do
            sh.cmd 'xcodebuild -version -sdk'

            sh.if use_ruby_motion do
              sh.cmd 'motion --version'
            end
            sh.elif '-f Podfile' do
              sh.cmd 'pod --version'
            end
          end
        end

        def export
          super

          sh.export 'TRAVIS_XCODE_SDK', config[:xcode_sdk]
          sh.export 'TRAVIS_XCODE_SCHEME', config[:xcode_scheme]
          sh.export 'TRAVIS_XCODE_PROJECT', config[:xcode_project]
          sh.export 'TRAVIS_XCODE_WORKSPACE', config[:xcode_workspace]
        end

        def setup
          super

          sh.cmd "echo '#!/bin/bash\n# no-op' > /usr/local/bin/actool"
          sh.cmd 'chmod +x /usr/local/bin/actool'
          sh.cmd "osascript -e 'set simpath to \"/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Applications/iPhone Simulator.app/Contents/MacOS/iPhone Simulator\" as POSIX file' -e 'tell application \"Finder\"' -e 'open simpath' -e 'end tell'"
        end

        def install
          sh.if '-f Gemfile' do
            sh.cmd 'bundle install', fold: 'install.bundler', retry: true
          end

          sh.if '-f Podfile' do
            sh.cmd 'pod install', fold: 'install.cocoapods', retry: true
          end
        end

        def script
          sh.if use_ruby_motion(with_bundler: true) do
            sh.cmd 'bundle exec rake spec'
          end

          sh.elif use_ruby_motion do
            sh.cmd 'rake spec'
          end

          sh.else do
            if config[:xcode_scheme] && (config[:xcode_project] || config[:xcode_workspace])
              sh.cmd "xctool #{xctool_args} build test"
            else
              deprecate DEPRECATED_MISSING_WORKSPACE_OR_PROJECT
            end
          end
        end

        private

          def use_ruby_motion(options = {})
            condition = '-f Rakefile && "$(cat Rakefile)" =~ require\ [\\"\\\']motion/project'
            condition << ' && -f Gemfile' if options.delete(:with_bundler)
            condition
          end

          def xctool_args
            config[:xctool_args].to_s.tap do |xctool_args|
              %w(project workspace scheme sdk).each do |var|
                xctool_args << " -#{var} #{config[:"xcode_#{var}"].to_s.shellescape}" if config[:"xcode_#{var}"]
              end
            end.strip
          end

          DEPRECATED_MISSING_WORKSPACE_OR_PROJECT = <<-msg
            Using Objective-C testing without specifying a scheme and either a workspace or a project is deprecated.
            Check out our documentation for more information: http://about.travis-ci.org/docs/user/languages/objective-c/
          msg
      end
    end
  end
end
