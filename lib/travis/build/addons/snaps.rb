require 'travis/build/addons/base'
require 'shellwords'

module Travis
  module Build
    class Addons
      class Snaps < Base
        SUPER_USER_SAFE = true
        SUPPORTED_OPERATING_SYSTEMS = [
          /^linux/
        ].freeze
        SUPPORTED_DISTS = %w(
          xenial
          bionic
        ).freeze

        def before_prepare?
          SUPPORTED_OPERATING_SYSTEMS.any? do |os_match|
            data[:config][:os].to_s =~ os_match
          end && SUPPORTED_DISTS.include?(data[:config][:dist].to_s)
        end

        def before_prepare
          return if config_snaps.empty?
          sh.newline
          sh.fold('snap') do
            install_snaps
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

        def install_snaps
          sh.echo "Installing #{config_snaps.count} Snaps", ansi: :yellow

          # install core separately
          sh.cmd "sudo snap install core", echo: true, timing: true, assert: true

          config_snaps.each do |snap|
            sh.cmd "sudo snap install #{expand_install_command(snap)}", echo: true, timing: true, assert: true
          end

          sh.cmd "sudo snap list", echo: true, timing: true, assert: true
        end

        def config_snaps
          @config_snaps ||= Array(config).flatten.compact
        rescue TypeError => e
          if e.message =~ /no implicit conversion of Symbol into Integer/
            raise Travis::Build::SnapsConfigError.new
          end
        end

        def expand_install_command(snap)
          return snap if snap.is_a?(String)

          command = snap[:name]

          if snap[:classic] == true
            command += " --classic"
          end

          if snap.has_key?(:channel)
            command += " --channel=#{snap[:channel]}"
          end

          command
        end
      end
    end
  end
end
