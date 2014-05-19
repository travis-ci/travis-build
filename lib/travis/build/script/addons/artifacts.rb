module Travis
  module Build
    class Script
      module Addons
        class Artifacts
          REQUIRES_SUPER_USER = false

          CONCURRENCY = 5
          MAX_SIZE = Float(1024 * 1024 * 50)

          attr_accessor :script, :config

          def initialize(script, config)
            @script = script
            @config = config
          end

          def after_script
            return if config.empty?
            script.cmd('echo', echo: false, assert: false)

            if pull_request?
              script.cmd('echo "Artifacts support disabled for pull requests"', echo: false, assert: false)
              return
            end

            unless branch_runnable?
              script.cmd(%Q{echo "Artifacts support not enabled for the current branch (#{data.branch.inspect})"}, echo: false, assert: false)
              return
            end

            run
          end

          private

          def run
            override_controlled_params
            options = config.delete(:options)

            return unless validate!

            script.cmd('echo -e "Uploading Artifacts (\033[33;1mBETA\033[0m)"', echo: false, assert: false)
            script.fold('artifacts.0') do
              install
              configure_env
              script.set('PATH', '$HOME/bin:$PATH', echo: false, assert: false)
            end
            script.fold('artifacts.1') do
              script.cmd(
                "artifacts upload #{options}",
                assert: false
              )
            end
            script.cmd('echo "Done uploading artifacts"', echo: false, assert: false)
          end

          def branch
            config[:branch]
          end

          def pull_request?
            data.pull_request
          end

          def branch_runnable?
            return true if branch.nil?
            return branch.include?(data.branch) if branch.respond_to?(:each)
            branch == data.branch
          end

          def data
            script.data
          end

          def install
            script.cmd(install_script, echo: false, assert: false)
          end

          def install_script
            @install_script ||= <<-EOF.gsub(/^\s{14}/, '')
              ARTIFACTS_DEST=$HOME/bin/artifacts
              mkdir -p $(dirname "$ARTIFACTS_DEST")
              curl -sL -o "$ARTIFACTS_DEST" \
                https://s3.amazonaws.com/meatballhat/artifacts/linux/amd64/meatballhat/artifacts/stable/artifacts
              chmod +x "$ARTIFACTS_DEST"
              PATH="$(dirname "$ARTIFACTS_DEST"):$PATH" artifacts -v
            EOF
          end

          def override_controlled_params
            %w(max_size concurrency target_paths).map(&:to_sym).each do |k|
              config.delete(k)
            end
            config[:max_size] = MAX_SIZE
            config[:concurrency] = CONCURRENCY
            config[:target_paths] = target_paths
          end

          def target_paths
            @target_paths ||= File.join(
              data.slug,
              data.build[:number],
              data.job[:number]
            )
          end

          def configure_env
            config[:paths] ||= '$(git ls-files -o | tr "\n" ":")'
            config[:log_format] ||= 'multiline'

            config.each { |key, value| setenv(key.to_s.upcase, value) }
          end

          def setenv(key, value, prefix = 'ARTIFACTS_')
            value = value.map(&:to_s).join(':') if value.respond_to?(:each)
            script.set(
              "#{prefix}#{key}", %Q{"#{value}"}, echo: setenv_echoable?(key), assert: false
            )
          end

          def setenv_echoable?(key)
            %w(PATHS).include?(key)
          end

          def validate!
            valid = true
            unless config[:key]
              script.cmd('echo "Artifacts config missing :key param"', echo: false, assert: false)
              valid = false
            end
            unless config[:secret]
              script.cmd('echo "Artifacts config missing :secret param"', echo: false, assert: false)
              valid = false
            end
            unless config[:bucket]
              script.cmd('echo "Artifacts config missing :bucket param"', echo: false, assert: false)
              valid = false
            end
            valid
          end
        end
      end
    end
  end
end
