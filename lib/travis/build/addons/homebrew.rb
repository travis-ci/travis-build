require 'travis/build/addons/base'
require 'shellwords'

module Travis
  module Build
    class Addons
      class Homebrew < Base
        SUPPORTED_OPERATING_SYSTEMS = [
          /^osx.*/
        ].freeze

        def before_prepare?
          SUPPORTED_OPERATING_SYSTEMS.any? do |os_match|
            data[:config][:os].to_s =~ os_match
          end
        end

        def before_prepare
          sh.fold('brew') do
            update_homebrew if update_homebrew?
            install_homebrew_packages
          end
        end

        private

        def config
          @config ||= Hash(super)
        end

        def update_homebrew?
          config[:update]
        end

        def update_homebrew
          sh.echo "Updating Homebrew", ansi: :yellow
          sh.cmd 'brew update', echo: true, timing: true
        end

        def config_packages
          @config_packages ||= Array(config[:packages]).flatten.compact
        end

        def config_casks
          @config_casks ||= Array(config[:casks]).flatten.compact
        end

        def config_taps
          @config_taps ||= Array(config[:taps]).flatten.compact
        end

        def brewfile_contents
          brewfile = StringIO.new
          config_taps.each do |tap|
            brewfile.puts "tap '#{tap}'"
          end
          config_packages.each do |package|
            brewfile.puts "brew '#{package}'"
          end
          config_casks.each do |cask|
            brewfile.puts "cask '#{cask}'"
          end
          brewfile.string
        end

        def install_homebrew_packages
          sh.echo "Installing Homebrew Packages", ansi: :yellow
          sh.file '~/.Brewfile', brewfile_contents
          sh.cmd 'brew bundle --global', echo: true, timing: true
        end
      end
    end
  end
end
