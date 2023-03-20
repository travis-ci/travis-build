require 'shellwords'
require 'travis/build/addons/base'

module Travis
  module Build
    class Addons
      class TensorFlow < Base
        ALLOWED_VERSIONS = %w[0.12.1 1.0.0 1.0.1 1.1.0 1.2.0 1.2.1 1.3.0 1.4.0 1.4.1 1.5.0 1.5.1
                              1.6.0 1.7.0 1.7.1 1.8.0 1.9.0 1.10.0 1.10.1 1.11.0 1.12.0 1.12.2 1.12.3
                              1.13.1 1.13.2 1.14.0 1.15.0 1.15.2 1.15.31.15.4 1.15.5 2.0.0 2.0.1 2.0.2 2.0.3 2.0.4 2.1.0 2.1.1 2.1.2 2.1.3 
                              2.1.4 2.2.0 2.2.1 2.2.2 2.2.3 2.3.0 2.3.1 2.3.2 2.3.3 2.3.4 2.4.0 2.4.1 2.4.2 2.4.3 2.4.4 2.5.0 2.5.1 2.5.2 
                              2.6.0rc0 2.6.0rc1 2.6.0rc2 2.6.0 2.6.1 2.6.2].freeze

        def after_prepare
          sh.fold 'tenser_flow' do
            if version.nil?
              sh.echo "Invalid version '#{raw_version}' given. Valid versions are: #{ALLOWED_VERSIONS.join(' ')}", ansi: :red
              return
            end
            sh.echo "Installing TensorFlow version: #{version}", ansi: :yellow
            sh.cmd "pip install --trusted-host pip.cache.travis-ci.com -i http://pip.cache.travis-ci.com/root/pypi/+simple/ tensorflow==#{version}", sudo: false
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
