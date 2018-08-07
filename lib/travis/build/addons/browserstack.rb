require 'travis/build/addons/base'
require 'net/http'

module Travis
  module Build
    class Addons
      class Browserstack < Base
        # mark safe for use on containers
        SUPER_USER_SAFE = true
        BROWSERSTACK_HOME = '$HOME/.browserstack'
        BROWSERSTACK_BIN_FILE = 'BrowserStackLocal'
        BROWSERSTACK_BIN_URL = 'https://www.browserstack.com/browserstack-local'
        ENV_USER = 'BROWSERSTACK_USERNAME'
        ENV_KEY = 'BROWSERSTACK_ACCESS_KEY'
        ENV_LOCAL = 'BROWSERSTACK_LOCAL'
        ENV_LOCAL_IDENTIFIER = 'BROWSERSTACK_LOCAL_IDENTIFIER'
        ENV_APP_ID = 'BROWSERSTACK_APP_ID'
        ENV_CUSTOM_ID = 'BROWSERSTACK_CUSTOM_ID'
        ENV_SHAREABLE_ID = 'BROWSERSTACK_SHAREABLE_ID'
        BROWSERSTACK_APP_AUTOMATE_URL = 'https://api-cloud.browserstack.com/app-automate/upload'

        def before_before_script
          browserstack_key = access_key.to_s
          sh.fold "browserstack.install" do
            if browserstack_key.empty?
              sh.echo "access_key is invalid.", ansi: :red
              return
            end

            sh.echo "Installing BrowserStack Local", ansi: :yellow
            case data[:config][:os]
            when 'linux'
              bin_package = "#{BROWSERSTACK_BIN_FILE}-linux-x64.zip"
            when 'osx'
              bin_package = "#{BROWSERSTACK_BIN_FILE}-darwin-x64.zip"
            else
              sh.echo "Unsupported platform: $TRAVIS_OS_NAME.", ansi: :yellow
              return
            end

            bin_url = "#{BROWSERSTACK_BIN_URL}/#{bin_package}"
            sh.cmd "mkdir -p #{BROWSERSTACK_HOME}"
            sh.cmd "wget -O /tmp/#{bin_package} #{bin_url}", echo: true, timing: true, retry: true
            sh.cmd "unzip -d #{BROWSERSTACK_HOME}/ /tmp/#{bin_package} 2>&1 > /dev/null", echo: false
            sh.chmod "+x", "#{BROWSERSTACK_HOME}/#{BROWSERSTACK_BIN_FILE}", echo: false
          end

          sh.fold 'browserstack.start' do
            sh.echo 'Starting BrowserStack Local', ansi: :yellow
            sh.cmd "#{build_start_command(browserstack_key)}"
            browserstack_user = username.to_s
            sh.export ENV_USER, browserstack_user + "-travis", echo: true unless browserstack_user.empty?
            sh.export ENV_KEY, browserstack_key, echo: false
            sh.export ENV_LOCAL, 'true', echo: true
          end

          if app_path && !app_path.empty?
            if !upload_app()
              raise "app upload failure"
            end
          end
        end

        def after_after_script
          sh.if "-f #{BROWSERSTACK_HOME}/#{BROWSERSTACK_BIN_FILE}" do
            sh.fold 'browserstack.stop' do
              sh.echo 'Stopping BrowserStack Local', ansi: :yellow
              sh.cmd "#{build_stop_command}"
            end
          end
        end

        def build_start_command(access_key)
          args = []
          options = {
            :localIdentifier => method(:local_identifier),
            :v => method(:verbose),
            :f => method(:folder),
            :force => method(:force),
            :only => method(:only),
            :forcelocal => method(:force_local),
            :onlyAutomate => method(:only_automate),
            :proxyHost => method(:proxy_host),
            :proxyPort => method(:proxy_port),
            :proxyUser => method(:proxy_user),
            :proxyPass => method(:proxy_pass)
          }

          options.each do |arg, fn|
            v = fn.call
            if !v.nil?
              if (!!v == v)
                args.push("-#{arg}") if v
              else
                args.push("-#{arg}")
                args.push(v)
              end
            end
          end

          local_args = args.empty? ? "" : " #{args.join(' ')}"
          "#{BROWSERSTACK_HOME}/#{BROWSERSTACK_BIN_FILE} -d start #{access_key}#{local_args}" if !access_key.nil?
        end

        def build_stop_command
          "#{BROWSERSTACK_HOME}/#{BROWSERSTACK_BIN_FILE} -d stop"
        end

        private
          def username
            config[:username]
          end

          def access_key
            key = config[:access_key] || config[:accessKey]
            key if key.to_s =~ /^[a-zA-Z0-9]+$/
          end

          def verbose
            verbose = config[:verbose] || config[:v]
            (verbose.to_s == 'true')
          end

          def force
            force = config[:force]
            (force.to_s == 'true')
          end

          def only
            config[:only]
          end

          def local_identifier
            local_id = (config[:local_identifier] || config[:localIdentifier]).to_s
            unless local_id.empty?
              sh.export ENV_LOCAL_IDENTIFIER, local_id, echo: true
              local_id
            else
              sh.export ENV_LOCAL_IDENTIFIER, "travis-${TRAVIS_BUILD_NUMBER}-${TRAVIS_JOB_NUMBER}", echo: true
              "$#{ENV_LOCAL_IDENTIFIER}"
            end
          end

          def folder
            config[:folder] || config[:f]
          end

          def force_local
            force_local = config[:force_local] || config[:forcelocal]
            (force_local.to_s == 'true')
          end

          def only_automate
            only_automate = config[:only_automate] || config[:onlyAutomate]
            (only_automate.to_s == 'true')
          end

          def proxy_host
            config[:proxy_host] || config[:proxyHost]
          end

          def proxy_port
            config[:proxy_port] || config[:proxyPort]
          end

          def proxy_user
            config[:proxy_user] || config[:proxyUser]
          end

          def proxy_pass
            config[:proxy_pass] || config[:proxyPass]
          end

          def custom_id
            config[:custom_id] || config[:customId]
          end

          def app_path
            config[:app_path] || config[:appPath]
          end

          def export_app_variables()
            sh.export(ENV_APP_ID, response['app_url'], echo: true)
            sh.export(ENV_CUSTOM_ID, response['custom_id'], echo: false) \
              if response['custom_id'] && !response['custom_id'].empty?
            sh.export(ENV_SHAREABLE_ID, response['shareable_id'], echo: false) \
              if response['shareable_id'] && !response['shareable_id'].empty?
            return true
          end

          def upload_app()
            if !File.exist?(app_path)
              return false
            else
              if custom_id && !custom_id.empty?
                response = `curl --retry 3 --retry-connrefused --retry-delay 2 \
                  -u "#{username}:#{access_key}" -X POST #{BROWSERSTACK_APP_AUTOMATE_URL} -F \
                  "file=@/#{app_path}" -F \'data={"custom_id": "#{custom_id}"}\'`
              else
                response = `curl --retry 3 --retry-connrefused --retry-delay 2\
                  -u "#{username}:#{access_key}" -X POST #{BROWSERSTACK_APP_AUTOMATE_URL} -F \
                  "file=@/#{app_path}"`
              end
              response = JSON.parse(response)
              return false if !response['app_url'] || response['app_url'].empty?
              export_app_variables()
            end
          end
      end
    end
  end
end
