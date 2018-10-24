require 'travis/build/addons/base'
require 'net/http'
require 'json'

module Travis
  module Build
    class Addons
      class Browserstack < Base
        # mark safe for use on containers
        SUPER_USER_SAFE = true
        BROWSERSTACK_HOME = '${TRAVIS_HOME}/.browserstack'
        BROWSERSTACK_BIN_FILE = 'BrowserStackLocal'
        BROWSERSTACK_BIN_URL = 'https://www.browserstack.com/browserstack-local'
        ENV_USER = 'BROWSERSTACK_USER'
        ENV_USERNAME = 'BROWSERSTACK_USERNAME'
        ENV_KEY = 'BROWSERSTACK_ACCESS_KEY'
        ENV_LOCAL = 'BROWSERSTACK_LOCAL'
        ENV_LOCAL_IDENTIFIER = 'BROWSERSTACK_LOCAL_IDENTIFIER'
        ENV_APP_ID = 'BROWSERSTACK_APP_ID'
        ENV_CUSTOM_ID = 'BROWSERSTACK_CUSTOM_ID'
        ENV_SHAREABLE_ID = 'BROWSERSTACK_SHAREABLE_ID'
        BROWSERSTACK_APP_AUTOMATE_URL = 'https://api-cloud.browserstack.com/app-automate/upload'

        def before_before_script
          sh.fold "browserstack.install" do
            install_browserstack
          end

          unless browserstack_key.empty?
            sh.fold 'browserstack.start' do
              start_browserstack
            end
          end

          if app_path && !app_path.empty?
            upload_app()
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

          def browserstack_key
            access_key.to_s
          end

          def install_browserstack
            if browserstack_key.empty?
              sh.echo "Browserstack access_key is invalid.", ansi: :red
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

          def start_browserstack
            sh.echo 'Starting BrowserStack Local', ansi: :yellow
            sh.cmd "#{build_start_command(browserstack_key)}"
            browserstack_user = username.to_s
            sh.export ENV_USER, browserstack_user + "-travis", echo: true unless browserstack_user.empty?
            sh.export ENV_USERNAME, browserstack_user + "-travis", echo: true unless browserstack_user.empty?
            sh.export ENV_KEY, browserstack_key, echo: false
            sh.export ENV_LOCAL, 'true', echo: true
          end

          def custom_id
            config[:custom_id] || config[:customId]
          end

          def app_path
            path = config[:app_path] || config[:appPath]
            return File.join('$TRAVIS_BUILD_DIR', path) if path && !path.empty?
            return path
          end

          def upload_app()
            upload_command = "curl -u \"#{username}:#{browserstack_key}\" -X POST #{BROWSERSTACK_APP_AUTOMATE_URL} -F \"file=@#{app_path}\""
            if custom_id && !custom_id.empty?
              upload_command += " -F 'data={\"custom_id\": \"#{custom_id}\"}'"
            end
            sh.fold "browserstack app upload" do
              sh.if "-e #{app_path}" do
                sh.cmd "#{upload_command} | tee $TRAVIS_BUILD_DIR/app_upload_out"
                sh.export(ENV_APP_ID, "`cat $TRAVIS_BUILD_DIR/app_upload_out | jq -r .app_url`")
                sh.export(ENV_CUSTOM_ID, "`cat $TRAVIS_BUILD_DIR/app_upload_out | jq -r .custom_id`")
                sh.export(ENV_SHAREABLE_ID, "`cat $TRAVIS_BUILD_DIR/app_upload_out | jq -r .shareable_id`")
                sh.cmd("rm $TRAVIS_BUILD_DIR/app_upload_out")
              end
              sh.else do
                sh.echo("App file not found")
              end
            end
          end
      end
    end
  end
end
