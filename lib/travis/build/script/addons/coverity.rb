module Travis
  module Build
    class Script
      module Addons
        class Coverity
          def initialize(script, config)
            @script = script
            @config = config.respond_to?(:to_hash) ? config.to_hash : {}
            @config[:build_utility_version] ||= '6.6.1'
          end

          def platform
            @platform ||= begin
              case (uname = %x[uname -a])
              when /Darwin/;        'macosx'  # Actually for dev testing only
              when /i.86/;          'linux32'
              when /amd64|x86_64/;  'linux64'
              else                  fail "Unknown platform per '#{uname}'"
              end 
            end
          end

          def download_url
            "https://scan.coverity.com/build_tool/cov-analysis-#{platform}-#{@config[:build_utility_version]}.tar.gz"
          end

          def upload_url
            "http://scan5.coverity.com/cgi-bin/upload.py"
          end

          def tmp_tar
            "/tmp/cov-analysis.tar.gz"
          end

          def install_dir
            "/usr/local"
          end

          def cov_analysis_base_dir
            "#{install_dir}/cov-analysis"
          end

          def cov_analysis_dir
            "#{cov_analysis_base_dir}/cov-analysis-#{platform}-#{@config[:build_utility_version]}"
          end

          def download_build_utility
            <<-BASH.squeeze(' ').lines.map { |s| s.strip }.join("\n") << "\n"
              set -e
              echo -e \"\033[33;1mLooking for #{cov_analysis_dir}...\033[0m\"
              if [ -d #{cov_analysis_dir} ]
              then
                echo -e \"\033[33;1mUsing existing Coverity Build Utility v#{@config[:build_utility_version]}\033[0m\"
              else
                echo -e \"\033[33;1mDownloading Coverity Build Utility v#{@config[:build_utility_version]}\033[0m\"
                sudo mkdir -p #{cov_analysis_base_dir}
                sudo chown -R travis #{cov_analysis_base_dir}
                echo wget -O #{tmp_tar} #{download_url}
                pushd #{cov_analysis_base_dir}
                tar xf #{tmp_tar}
                popd
              fi
            BASH
          end

          def build_command
            <<-BASH.squeeze(' ').lines.map { |s| s.strip }.join("\n") << "\n"
              COVERITY_UNSUPPORTED=1 PATH=#{cov_analysis_dir}/bin:${PATH} cov-build --dir cov-int make -j8
              tar czf cov-int.tgz cov-int
            BASH
          end

          def submit_results
            <<-BASH.squeeze(' ').lines.map { |s| s.strip }.join("\n") << "\n"
              curl -X POST \
                -d 'email=#{@config[:email]}' \
                -d 'project=#{@config[:project][:name]}' \
                -d 'version=#{@config[:project][:version]}' \
                -d 'description=#{@config[:project][:description]}' \
                -d "token=$COVERITY_SCAN_TOKEN" \
                -d 'file=@cov-int.tgz' \
                #{upload_url}
            BASH
          end

          def build_and_submit
            <<-BASH.squeeze(' ').lines.map { |s| s.strip }.join("\n") << "\n"
              set -e
              #{build_command.chomp}
              #{submit_results.chomp}
            BASH
          end

          def install
            @script.fold('install_coverity') do |script|
              script.cmd download_build_utility, assert: false, echo: false
            end
          end

          def script
            @script.fold('build_coverity') do |script|
              script.cmd build_and_submit, assert: false, echo: false
            end
          end

        end
      end
    end
  end
end

