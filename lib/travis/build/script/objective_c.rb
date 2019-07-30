require 'shellwords'
require 'travis/build/script/shared/bundler'
require 'travis/build/script/shared/chruby'
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

        def setup
          super
          sh.if podfile? do
            suppress_cocoapods_msg
          end
        end

        def announce
          super
          sh.fold 'announce' do
            sh.cmd 'xcodebuild -version -sdk'
            sh.cmd 'xcrun simctl list'
          end

          sh.if use_ruby_motion do
            sh.cmd 'motion --version'
          end
          sh.if podfile? do
            sh.cmd 'pod --version'
          end
        end

        def export
          super
          sh.echo "Disabling Homebrew auto update. If your Homebrew package requires Homebrew DB be up to date, please run \\`brew update\\` explicitly.", ansi: :yellow
          sh.export 'HOMEBREW_NO_AUTO_UPDATE', '1', echo: true
          [:sdk, :scheme, :project, :workspace, :destination].each do |key|
            sh.export "TRAVIS_XCODE_#{key.upcase}", config[:"xcode_#{key}"].to_s.shellescape, echo: false
          end
        end

        def setup_cache
          return unless use_directory_cache?
          super

          sh.if podfile? do
            sh.newline
            if data.cache?(:cocoapods)
              sh.fold 'cache.cocoapods' do
                sh.newline
                directory_cache.add("#{pod_dir}/Pods")
              end
            end
          end
          sh.else do
            if data.cache?(:cocoapods)
              sh.echo "cocoapods caching configured but a podfile is not found. Caching may not work.", ansi: :yellow
            else
              sh.raw ':'
            end
          end
        end

        def install
          super
          sh.if podfile? do
            sh.if "! ([[ -f #{pod_dir}/Podfile.lock && -f #{pod_dir}/Pods/Manifest.lock ]] && cmp --silent #{pod_dir}/Podfile.lock #{pod_dir}/Pods/Manifest.lock)", raw: true do
              sh.fold('install.cocoapods') do

                sh.cmd "pushd #{pod_dir}"

                sh.if gemfile? do
                  sh.echo "Installing Pods with 'bundle exec pod install'", ansi: :yellow
                  sh.cmd 'bundle exec pod install', retry: true
                end

                sh.else do
                  sh.echo "Installing Pods with 'pod install'", ansi: :yellow
                  sh.cmd 'pod install', retry: true
                end

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
              if use_xctool?
                sh.cmd "xctool #{xcodebuild_args} build test"
              else
                sh.cmd "set -o pipefail && xcodebuild #{xcodebuild_args} build test | xcpretty"
              end
            else
              # deprecate DEPRECATED_MISSING_WORKSPACE_OR_PROJECT
              sh.cmd "echo -e \"\\033[33;1mWARNING:\\033[33m Using Objective-C testing without specifying a scheme and either a workspace or a project is deprecated.\"", echo: false, timing: true
              sh.cmd "echo \"  Check out our documentation for more information: http://about.travis-ci.org/docs/user/languages/objective-c/\"", echo: false, timing: true
              sh.failure
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

          def use_xctool?
            %w[xcode6.4 xcode7.3].include? config[:osx_image]
          end

          def xcodebuild_args
            config[:xcodebuild_args].to_s.tap do |xcodebuild_args|
              %w[project workspace scheme sdk destination].each do |var|
                xcodebuild_args << " -#{var} #{config[:"xcode_#{var}"].to_s.shellescape}" if config[:"xcode_#{var}"]
              end
            end.strip
          end

          def suppress_cocoapods_msg
            sh.mkdir "$HOME/.cocoapods", recursive: true
            sh.cmd "echo \"new_version_message: false\" >> $HOME/.cocoapods/config.yaml"
          end

          # DEPRECATED_MISSING_WORKSPACE_OR_PROJECT = <<-msg
          #   Using Objective-C testing without specifying a scheme and either a workspace or a project is deprecated.
          #   Check out our documentation for more information: http://about.travis-ci.org/docs/user/languages/objective-c/
          # msg
      end
    end
  end
end
