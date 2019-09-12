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
          # keeping empty for now
        end

        def before_configure
          # keeping empty for now
        end

        def config
          @config ||= Hash(super)
        end

        def install_pkg
          sh.echo "Installing #{config_pkg.count} packages", ansi: :yellow

          packages = config_pkg.map{|v| Shellwords.escape(v)}.join(' ')
          sh.cmd ["sudo pkg install", "-y", packages].join(' '), echo: true, timing: true, assert: true
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
