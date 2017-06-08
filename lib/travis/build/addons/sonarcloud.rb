require 'digest/md5'
require 'shellwords'
require 'travis/build/addons/base'

module Travis
  module Build
    class Addons
      class Sonarcloud < Base
        SUPER_USER_SAFE = true
        DEFAULT_SQ_HOST_URL = "https://sonarcloud.io"
        SCANNER_CLI_VERSION = "2.8"
        SCANNER_HOME = "$HOME/.sonarscanner"
        CACHE_DIR = "$HOME/.sonar/cache"
        SCANNER_CLI_REPO = "http://repo1.maven.org/maven2"
        BUILD_WRAPPER_LINUX = "build-wrapper-linux-x86"
        BUILD_WRAPPER_MACOSX = "build-wrapper-macosx-x86"

        SKIP_MSGS = {
          branch_disabled: 'this branch is not master or it does not match declared branches',
          no_pr_token: 'no PR analysis can be done by SonarQube Scanner because the SONAR_GITHUB_TOKEN is not defined',
          no_secure_env: 'it is not running in a secure environment'
        }
          
        def before_before_script
          sh.fold 'sonarcloud.addon' do
            folded
          end
        end
        
        def folded
          sh.echo "SonarCloud addon", echo: false, ansi: :yellow
          sh.echo "addon hash: #{addon_hash}", echo: false
          @sonarqube_scanner_params = {}
          install_sonar_scanner
          install_build_wrapper
        
          if !data.secure_env?
            skip :no_secure_env
            return
          elsif !branch_valid?
            skip :branch_disabled
            return
          end
        
          export_tokens

          if data.pull_request
            sh.if "-z $SONAR_GITHUB_TOKEN" do
              skip :no_pr_token
            end
            sh.else do
              run
            end
            return
          end
        
          run
        end
        
        def export_tokens
          if token
            sh.export 'SONAR_TOKEN', token, echo: false
          end
          if github_token
            sh.export 'SONAR_GITHUB_TOKEN', github_token, echo: false
          end
        end
          
        def skip(reason)
          sh.echo "Skipping SonarCloud Scan because " + SKIP_MSGS[reason], echo: false, ansi: :yellow
          sh.export 'SONARQUBE_SKIPPED', "true", echo: true
          export_scanner_params({'sonar.scanner.skip'=> 'true'})
        end
        
        def install_sonar_scanner
          sh.echo "Preparing SonarQube Scanner CLI", echo: false, ansi: :yellow
          scr = <<SH
  rm -rf "#{SCANNER_HOME}"
  mkdir -p "#{SCANNER_HOME}"
  curl -sSLo "#{SCANNER_HOME}/sonar-scanner.zip" "#{SCANNER_CLI_REPO}/org/sonarsource/scanner/cli/sonar-scanner-cli/#{SCANNER_CLI_VERSION}/sonar-scanner-cli-#{SCANNER_CLI_VERSION}.zip"
  unzip "#{SCANNER_HOME}/sonar-scanner.zip" -d "#{SCANNER_HOME}"
SH
          sh.raw(scr, echo: false)
          sh.export 'SONAR_SCANNER_HOME', "#{SCANNER_HOME}/sonar-scanner-#{SCANNER_CLI_VERSION}", echo: true
          sh.export 'PATH', %{"$PATH:#{SCANNER_HOME}/sonar-scanner-#{SCANNER_CLI_VERSION}/bin"}, echo: false
        end
        
        def install_build_wrapper
          if language == "java" || language == "node_js"
            sh.echo "Not installing SonarSource build-wrapper because it's a Java or Javascript project", echo: false, ansi: :yellow
            return
          end
          
          sh.echo "Preparing build wrapper for SonarSource C/C++ plugin", echo: false, ansi: :yellow
            
          case os
            when 'linux'
              build_wrapper=BUILD_WRAPPER_LINUX
            when 'osx'
              build_wrapper=BUILD_WRAPPER_MACOSX
            else
              sh.echo "Can't install SonarSource build wrapper for platform: $TRAVIS_OS_NAME.", ansi: :yellow
              return
          end
            
          sh.cmd "sq_cpp_hash=$(curl -s #{DEFAULT_SQ_HOST_URL}/deploy/plugins/index.txt | grep \"^cpp\" | sed \"s/.*|\\(.*\\)/\\1/\")"
          sh.cmd "sq_build_wrapper_dir=#{CACHE_DIR}/$sq_cpp_hash"
            
          sh.if "-d $sq_build_wrapper_dir/#{build_wrapper}" do
            sh.echo "Using cached build wrapper"
          end
          sh.else do
            sh.mkdir "$sq_build_wrapper_dir", echo: false, recursive: true
            sh.cmd "curl -sSLo $sq_build_wrapper_dir/#{build_wrapper}.zip #{DEFAULT_SQ_HOST_URL}/static/cpp/#{build_wrapper}.zip", echo: false, retry: true
            sh.cmd "unzip -o $sq_build_wrapper_dir/#{build_wrapper}.zip -d $sq_build_wrapper_dir", echo: false
          end
            
          sh.export 'PATH', "\"$PATH:$sq_build_wrapper_dir/#{build_wrapper}\"", echo: false
        end
        
        def run
          sh.echo "Preparing SonarQube Scanner parameters", echo: false, ansi: :yellow
          if data.pull_request
            add_scanner_param("sonar.analysis.mode", "preview")
            add_scanner_param("sonar.github.repository", data.repository[:slug])
            add_scanner_param("sonar.github.pullRequest", data.pull_request)
            add_scanner_param("sonar.github.oauth", "$SONAR_GITHUB_TOKEN")
          end
          
          if organization
            add_scanner_param("sonar.organization", organization)
          end
            
          if data.branch != 'master'
            add_scanner_param("sonar.branch", data.branch)
          end
          
          add_scanner_param("sonar.host.url", DEFAULT_SQ_HOST_URL)
          
          sh.if "-n $SONAR_TOKEN" do
            export_scanner_params({ "sonar.login" => "$SONAR_TOKEN"})
          end
          sh.else do
            export_scanner_params
          end
        end
        
        private
        
          def branch_valid?
            cur_branch = data.branch || 'master'
            branches.each do |b|
              regex = Regexp.new b
              return true if regex.match(cur_branch)
            end
            false
          end
        
          def add_scanner_param(key, value)
            @sonarqube_scanner_params[key] = value
          end
          
          def export_scanner_params(additional_entries = nil)
            hash = @sonarqube_scanner_params.clone
            hash.merge!(additional_entries) if additional_entries
            
            if hash.length > 0
              json = "\"{ "
              hash.each_with_index do |(k,v), i|
                json << "\\\"#{k}\\\" : \\\"#{v}\\\""
                json << ", " unless i == (hash.length - 1)
              end
              json << " }\""
              sh.export 'SONARQUBE_SCANNER_PARAMS', json, echo: false
            end
          end
          
          def addon_hash
            Digest::MD5.hexdigest(File.read(__FILE__).gsub(/\s+/, ""))
          end
          
          def language
            data.language
          end
          
          def os
            data.config[:os]
          end
          
          def organization
            config[:organization]
          end
        
          def token
            config[:token] if data.secure_env?
          end
          
          def github_token
            config[:github_token] if data.secure_env?
          end
          
          def branches
            Array(config[:branches] || 'master')
          end

          def escape(str)
            Shellwords.escape(str.to_s)
          end
      end
    end
  end
end
