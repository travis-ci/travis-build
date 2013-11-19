module Travis
  module Build
    class Script
      module Addons
        class CoverityScan

          UPLOAD_URL    = 'http://scan5.coverity.com/cgi-bin/upload.py'
          TMP_TAR       = '/tmp/cov-analysis.tar.gz'
          INSTALL_DIR   = '/usr/local'

          def initialize(script, config)
            @script = script
            @config = config.respond_to?(:to_hash) ? config.to_hash : {}
          end

          def export_platform
            %q{export PLATFORM=`uname`}
          end

          def download_url
            "https://scan.coverity.com/download/$PLATFORM"
          end

          def cov_analysis_base_dir
            "#{INSTALL_DIR}/cov-analysis"
          end

          def cov_analysis_dir
            "#{cov_analysis_base_dir}/cov-analysis-$PLATFORM"
          end

          def download_build_utility
            <<-BASH.squeeze(' ').lines.map { |s| s.strip }.join("\n") << "\n"
              #{export_platform}
              echo -e \"\033[33;1mLooking for #{cov_analysis_dir}...\033[0m\"
              if [ -d #{cov_analysis_dir} ]
              then
                echo -e \"\033[33;1mUsing existing Coverity Build Utility\033[0m\"
              else
                echo -e \"\033[33;1mDownloading Coverity Build Utility\033[0m\"
                sudo mkdir -p #{cov_analysis_base_dir}
                sudo chown -R $USER #{cov_analysis_base_dir}
                wget -O #{TMP_TAR} #{download_url} --post-data "token=$COVERITY_SCAN_TOKEN&project=#{@config[:project][:name]}"
                if [ $? -ne 0 ]; then
                  echo -e \"\033[33;1mError downloading Coverity Build Utility\033[0m\"
                  exit
                fi
                pushd #{cov_analysis_base_dir}
                tar xf #{TMP_TAR}
                popd
              fi
            BASH
          end

          def build_command
            <<-BASH.squeeze(' ').lines.map { |s| s.strip }.join("\n") << "\n"
              #{export_platform}
              COVERITY_UNSUPPORTED=1 PATH=#{cov_analysis_dir}/bin:$PATH cov-build --dir cov-int #{@config[:build_command]}
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
                #{UPLOAD_URL}
            BASH
          end

          def install
            @script.fold('install_coverity') do |script|
              script.cmd download_build_utility, assert: false, echo: false
            end
          end

          def script
            @script.fold('build_coverity') do |script|
              script.cmd build_command, assert: false, echo: true
              script.cmd submit_results, assert: false, echo: true
            end
          end

        end
      end
    end
  end
end
