require 'shellwords'
require 'travis/build/addons/base'

module Travis
  module Build
    class Addons
      class TensorFlow < Base
        ALLOWED_VERSIONS = %w[2.11 1.15].freeze

        def after_prepare
          sh.fold 'tenser_flow' do
            if version.nil?
              sh.echo "Invalid version '#{raw_version}' given. Valid versions are: #{ALLOWED_VERSIONS.join(', ')}",
                      ansi: :red
              return
            end
            sh.echo "Installing TenserFlow version: #{version}", ansi: :yellow
            sh.cmd "pip install --trusted-host pip.cache.travis-ci.com -i http://pip.cache.travis-ci.com/root/pypi/+simple/ 'tensorflow==#{version}' --force-reinstall", sudo: false
          end
        end

        private

        def raw_version
          config.to_s.strip.shellescape
        end

        def version
          ALLOWED_VERSIONS.include?(raw_version) ? raw_version : nil
        end
      end
    end
  end
end