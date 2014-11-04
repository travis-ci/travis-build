require 'shellwords'
require 'travis/build/script/shared/bundler'
require 'travis/build/script/shared/rvm'

module Travis
  module Build
    class Script
      class ObjectiveC < Script
        DEFAULTS = {
          rvm:     'default',
          gemfile: 'Gemfile',
          podfile: 'Podfile',
        }

        include RVM
        include Bundler

        def announce
          super
          sh.fold 'announce' do
            sh.cmd 'xcodebuild -version -sdk', timing: true
            sh.cmd 'xctool -version', timing: true
          end

          sh.if use_ruby_motion do
            sh.cmd 'motion --version', timing: true
          end
          sh.if '-f Podfile' do
            sh.cmd 'pod --version', timing: true
          end
        end

        def export
          super

          sh.export 'TRAVIS_XCODE_SDK', config[:xcode_sdk].to_s.shellescape, echo: false
          sh.export 'TRAVIS_XCODE_SCHEME', config[:xcode_scheme].to_s.shellescape, echo: false
          sh.export 'TRAVIS_XCODE_PROJECT', config[:xcode_project].to_s.shellescape, echo: false
          sh.export 'TRAVIS_XCODE_WORKSPACE', config[:xcode_workspace].to_s.shellescape, echo: false
        end

        def setup
          super

          sh.cmd "echo '#!/bin/bash\n# no-op' > /usr/local/bin/actool", echo: false
          sh.cmd 'chmod +x /usr/local/bin/actool', echo: false
        end

        def install
          super

          directory_cache.add(sh, "#{pod_dir}/Pods") if data.cache?(:cocoapods)

          sh.if podfile? do
            sh.if "! ([[ -f #{pod_dir}/Podfile.lock && -f #{pod_dir}/Pods/Manifest.lock ]] && cmp --silent #{pod_dir}/Podfile.lock #{pod_dir}/Pods/Manifest.lock)", raw: true do
              sh.fold('install.cocoapods') do
                sh.echo "Installing Pods with 'pod install'", ansi: :yellow
                sh.cmd "pushd #{pod_dir}"
                sh.cmd 'pod install', retry: true
                sh.cmd 'popd'
              end
            end
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

        def use_directory_cache?
          super || data.cache?(:cocoapods)
        end

        private

          def podfile?
            "-f #{config[:podfile].to_s.shellescape}"
          end

          def pod_dir
            File.dirname(config[:podfile]).shellescape
          end

          def use_ruby_motion(options = {})
            condition = '-f Rakefile && "$(cat Rakefile)" =~ require\ [\\"\\\']motion/project'
            condition << ' && -f Gemfile' if options.delete(:with_bundler)
            condition
          end

          def xctool_args
            config[:xctool_args].to_s.tap do |xctool_args|
              %w[project workspace scheme sdk].each do |var|
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
