require 'digest/md5'
require 'shellwords'
require 'travis/build/addons/base'

module Travis
  module Build
    class Addons
      class Sonarcloud < Base
        SUPER_USER_SAFE = true
        DEFAULT_SQ_HOST_URL = "https://sonarcloud.io"
        SCANNER_HOME = "${TRAVIS_HOME}/.sonarscanner"
        CACHE_DIR = "${TRAVIS_HOME}/.sonar/cache"
        BUILD_WRAPPER_LINUX = "build-wrapper-linux-x86"
        BUILD_WRAPPER_MACOSX = "build-wrapper-macosx-x86"
        SCANNER_LOCAL_COPY_URL = "https://#{Travis::Build.config.app_host.to_s.strip}/files/sonar-scanner.zip".output_safe

        SKIP_MSGS = {
          branch_disabled: 'this branch is not master or it does not match declared branches',
          no_secure_env: 'it is not running in a secure environment'
        }

        def before_before_script
          @unfolded_warnings = []
          sh.fold 'sonarcloud.addon' do
            folded
          end
          @unfolded_warnings.each { |x| sh.echo x, echo: false, ansi: :yellow }
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
          run
        end

        def export_tokens
          if config[:token]
            sh.export 'SONAR_TOKEN', config[:token], echo: false
          end
          if config[:github_token]
            sh.export 'SONAR_GITHUB_TOKEN', config[:github_token], echo: false
          end
        end

        def skip(reason)
          sh.echo "Skipping SonarCloud Scan because " + SKIP_MSGS[reason], echo: false, ansi: :yellow
          sh.export 'SONARQUBE_SKIPPED', "true", echo: true
          add_scanner_param('sonar.scanner.skip', 'true')
          export_scanner_params
        end

        def install_sonar_scanner
          sh.echo "Preparing SonarQube Scanner CLI", echo: false, ansi: :yellow
          scr = <<SH
  rm -rf "#{SCANNER_HOME}"
  mkdir -p "#{SCANNER_HOME}"
  curl -sSLo "#{SCANNER_HOME}/sonar-scanner.zip" "#{SCANNER_LOCAL_COPY_URL}"
  unzip "#{SCANNER_HOME}/sonar-scanner.zip" -d "#{SCANNER_HOME}"
SH
          sh.raw(scr, echo: false)
          sh.mv "#{SCANNER_HOME}/sonar-scanner-*", "#{SCANNER_HOME}/sonar-scanner"
          sh.export 'SONAR_SCANNER_HOME', "#{SCANNER_HOME}/sonar-scanner", echo: true
          sh.export 'PATH', %{"$PATH:#{SCANNER_HOME}/sonar-scanner/bin"}, echo: false
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
              sh.echo "Can't install SonarSource build wrapper for platform: $TRAVIS_OS_NAME.", ansi: :red
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
            if github_token
              @unfolded_warnings.push("Github token found in the Travis YML file: running analysis in the deprecated mode. Remove that token and set it in the project settings in SonarCloud to benefit from the improved P/R analysis.")
              add_scanner_param("sonar.analysis.mode", "preview")
              add_scanner_param("sonar.github.repository", data.slug)
              add_scanner_param("sonar.github.pullRequest", data.pull_request)
              add_scanner_param("sonar.github.oauth", "$SONAR_GITHUB_TOKEN")
           else
              add_scanner_param("sonar.pullrequest.key", data.pull_request)
              add_scanner_param("sonar.pullrequest.branch", data.job[:pull_request_head_branch])
              add_scanner_param("sonar.pullrequest.base", data.branch)
              add_scanner_param("sonar.pullrequest.provider", "GitHub")
              add_scanner_param("sonar.pullrequest.github.repository", data.slug)
            end
          elsif !default_branch?
            if branches.nil? || branches.empty?
              add_scanner_param("sonar.branch.name", data.branch)
            else
              add_scanner_param("sonar.branch", data.branch)
              @unfolded_warnings.push("Remove declaration of the deprecated 'branches' option in your Travis YML file to benefit from the improved branches support. This deprecated option will be removed in the future.")
            end
          end

          if organization
            add_scanner_param("sonar.organization", organization)
          end

          add_scanner_param("sonar.host.url", DEFAULT_SQ_HOST_URL)

          if token
            add_scanner_param("sonar.login", "$SONAR_TOKEN")
          end

          export_scanner_params
        end

        private

          def branch_valid?
            if branches.nil? || branches.empty?
              return true
            else
              cur_branch = data.branch || 'master'
              branches.each do |b|
                regex = Regexp.new b
                return true if regex.match(cur_branch)
              end
              false
            end
          end

          def add_scanner_param(key, value)
            @sonarqube_scanner_params[key] = value
          end

          def export_scanner_params
            hash = @sonarqube_scanner_params.clone

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

          def default_branch?
            data.default_branch == data.branch
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
            config[:token] || get_env_var("SONAR_TOKEN") if data.secure_env?
          end

          def env_vars
            @env ||= Build::Env.new(data).groups.flat_map{|i| i.vars }
          end

          def get_env_var(key)
            # find first var with the given key. If one is found (not nil), return its value
            env_vars.find{|x| x.key == key }&.value
          end

          def github_token
            config[:github_token] || get_env_var("SONAR_GITHUB_TOKEN") if data.secure_env?
          end

          def branches
            Array(config[:branches])
          end

          def escape(str)
            Shellwords.escape(str.to_s)
          end
      end
    end
  end
end
