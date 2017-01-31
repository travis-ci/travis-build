require 'travis/build/addons/base'
require 'shellwords'

module Travis
  module Build
    class Addons
      class Brew < Base
        SUPER_USER_SAFE = true
        SUPPORTED_OPERATING_SYSTEMS = %w(
          osx
        ).freeze

        def before_prepare?
          SUPPORTED_OPERATING_SYSTEMS.include? data[:config][:os].to_s
        end

        def before_prepare
          sh.fold('brew') do
            install_brew_packages
          end
        end

        private
        def install_brew_packages
          sh.cmd "brew install #{brew_packages.join(' ')}", echo: true, timing: true
        end

        def brew_packages
          Array(config[:packages]).flatten.compact
        end
      end
    end
  end
end