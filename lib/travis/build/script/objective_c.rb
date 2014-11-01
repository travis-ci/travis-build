require 'shellwords'

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

        def use_directory_cache?
          super || data.cache?(:cocoapods)
        end

        def announce
          super
          sh.fold 'announce' do
            sh.cmd 'xcodebuild -version -sdk'
            sh.cmd 'xctool -version'
          end
          uses_rubymotion? then: 'motion --version'
          podfile? then: 'pod --version'
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

          podfile? do
            # cache cocoapods if it has been enabled
            directory_cache.add(sh, "#{pod_dir}/Pods") if data.cache?(:cocoapods)

            sh.if "! ([[ -f #{pod_dir}/Podfile.lock && -f #{pod_dir}/Pods/Manifest.lock ]] && cmp --silent #{pod_dir}/Podfile.lock #{pod_dir}/Pods/Manifest.lock)", raw_condition: true do
              sh.fold('install.cocoapods') do
                sh.echo 'Installing Pods with: pod install', ansi: :yellow
                sh.cmd "pushd #{pod_dir}"
                sh.cmd 'pod install', retry: true
                sh.cmd 'popd'
              end
            end
          end
        end

        def script
          uses_rubymotion?(with_bundler: true, then: 'bundle exec rake spec')
          uses_rubymotion?(elif: true, then: 'rake spec')

          sh.else do
            if config[:xcode_scheme] && (config[:xcode_project] || config[:xcode_workspace])
              sh.cmd "xctool #{xctool_args} build test"
            else
              sh.echo '\033[33;1mWARNING:\033[33m Using Objective-C testing without specifying a scheme and either a workspace or a project is deprecated.'
              sh.echo '  Check out our documentation for more information: http://about.travis-ci.org/docs/user/languages/objective-c/'
            end
          end
        end

        private

        def podfile?(*args, &block)
          sh.if "-f #{config[:podfile].to_s.shellescape}", *args, &block
        end

        def pod_dir
          File.dirname(config[:podfile]).shellescape
        end

        def uses_rubymotion?(*args)
          conditional = '-f Rakefile && "$(cat Rakefile)" =~ require\ [\\"\\\']motion/project'
          conditional << ' && -f Gemfile' if args.first && args.first.is_a?(Hash) && args.first.delete(:with_bundler)

          if args.first && args.first.is_a?(Hash) && args.first.delete(:elif)
            sh.elif conditional, *args
          else
            sh.if conditional, *args
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
