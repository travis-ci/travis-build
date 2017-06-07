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

        def announce
          super
          sh.fold 'announce' do
            sh.cmd 'xcodebuild -version -sdk'
            sh.cmd 'xctool -version'
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
          [:sdk, :scheme, :project, :workspace].each do |key|
            sh.export "TRAVIS_XCODE_#{key.upcase}", config[:"xcode_#{key}"].to_s.shellescape, echo: false
          end
        end

        def setup_cache
          return unless use_directory_cache?
          super

          sh.if podfile? do
            sh.echo ''
            if data.cache?(:cocoapods)
              sh.fold 'cache.cocoapods' do
                sh.echo ''
                directory_cache.add("#{pod_dir}/Pods")
              end
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
              sh.cmd "xctool #{xctool_args} build test"
            else
              # deprecate DEPRECATED_MISSING_WORKSPACE_OR_PROJECT
              sh.cmd "echo -e \"\\033[33;1mWARNING:\\033[33m Using Objective-C testing without specifying a scheme and either a workspace or a project is deprecated.\"", echo: false, timing: true
              sh.cmd "echo \"  Check out our documentation for more information: http://about.travis-ci.org/docs/user/languages/objective-c/\"", echo: false, timing: true
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

          # DEPRECATED_MISSING_WORKSPACE_OR_PROJECT = <<-msg
          #   Using Objective-C testing without specifying a scheme and either a workspace or a project is deprecated.
          #   Check out our documentation for more information: http://about.travis-ci.org/docs/user/languages/objective-c/
          # msg
      end
    end
  end
end
