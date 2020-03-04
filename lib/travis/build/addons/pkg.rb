require 'travis/build/addons/base'
require 'shellwords'

module Travis
  module Build
    class Addons
      class Pkg < Base
        SUPPORTED_OPERATING_SYSTEMS = %w[
          freebsd
        ].freeze

        def before_prepare?
          SUPPORTED_OPERATING_SYSTEMS.any? do |os_match|
            data[:config][:os].to_s == os_match
          end
        end

        def before_prepare
          return if config_pkg.empty?
          sh.newline
          sh.fold('pkg') do
            install_pkg
          end
          sh.newline
        end

        def before_configure?
          config
        end

        def before_configure
          sh.echo "Configuring default pkg options", ansi: :yellow
          tmp_dest = "${TRAVIS_TMPDIR}/99-travis-pkg-conf"
          sh.file tmp_dest, <<~PKG_CONF
            ASSUME_ALWAYS_YES=YES
            FETCH_RETRY=5
            FETCH_TIMEOUT=30
          PKG_CONF
          sh.cmd %Q{su -m root -c "mv #{tmp_dest} ${TRAVIS_ROOT}/usr/local/etc/pkg.conf"}
          if config[:branch] && config[:branch].to_s.downcase != 'quarterly'
            sed_find = 'pkg+http://pkg.FreeBSD.org/\([^/]*\)/quarterly'
            sed_replace = 'pkg+http://pkg.FreeBSD.org/\1/' + config[:branch]
            sed_cmd = %Q{sed -i'' -e 's,#{sed_find},#{sed_replace},' /etc/pkg/FreeBSD.conf}
            sh.cmd %Q{su -m root -c "#{sed_cmd}"}
          end
        end

        def config
          @config ||= Hash(super)
        end

        def install_pkg
          sh.echo "Installing #{config_pkg.count} packages", ansi: :yellow

          packages = config_pkg.map{|v| Shellwords.escape(v)}.join(' ')
          sh.cmd "su -m root -c 'pkg install #{packages}'", echo: true, timing: true, assert: true
        end

        def config_pkg
          @config_pkg ||= Array(config[:packages]).flatten.compact
        rescue TypeError => e
          if e.message =~ /no implicit conversion of Symbol into Integer/
            raise Travis::Build::PkgConfigError.new
          end
        end
      end
    end
  end
end
