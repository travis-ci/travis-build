require 'travis/build/addons/base'
require 'shellwords'

module Travis
  module Build
    class Addons
      class Yum < Base
        SUPPORTED_OPERATING_SYSTEMS = %w[
          linux
          /^linux.*/
        ].freeze

        SUPPORTED_DISTS = %w(
          rhel
        ).freeze

        def before_prepare?
          SUPPORTED_OPERATING_SYSTEMS.any? do |os_match|
            data[:config][:os].to_s == os_match
          end
        end

        def before_prepare
          return if config_yum.empty?
          sh.newline
          sh.fold('yum') do
            install_yum
          end
          sh.newline
        end

        def before_configure?
          config
        end

        def before_configure
          sh.echo "Configuring default yum options", ansi: :yellow
          tmp_dest = "${TRAVIS_TMPDIR}/99-travis-yum-conf"
          sh.file tmp_dest, <<~YUM_CONF
            assumeyes=1
            retries=5
            timeout=30
          YUM_CONF
          sh.cmd %Q{sudo mv #{tmp_dest} ${TRAVIS_ROOT}/usr/local/etc/yum.conf}
        end

        def config
          @config ||= Hash(super)
        end

        def install_yum
          sh.echo "Installing #{config_yum.count} packages", ansi: :yellow

          packages = config_yum.map{|v| Shellwords.escape(v)}.join(' ')
          sh.cmd "sudo yum install -y #{packages}", echo: true, timing: true, assert: true
        end

        def config_yum
          @config_yum ||= Array(config[:packages]).flatten.compact
        rescue TypeError => e
          if e.message =~ /no implicit conversion of Symbol into Integer/
            raise Travis::Build::YumConfigError.new
          end
        end
      end
    end
  end
end
