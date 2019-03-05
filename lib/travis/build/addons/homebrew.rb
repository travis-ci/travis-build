require 'travis/build/addons/base'
require 'shellwords'

module Travis
  module Build
    class Addons
      class Homebrew < Base
        SUPPORTED_OPERATING_SYSTEMS = %w[
          osx
        ].freeze

        BASELINE_RUBY_2_3 = '2.3.5'

        def before_before_install?
          SUPPORTED_OPERATING_SYSTEMS.any? do |os_match|
            data[:config][:os].to_s == os_match
          end
        end

        def before_before_install
          sh.fold('brew') do
            sh.if ruby_pre_2_3? do
              sh.echo "Homebrew requires Ruby 2.3 or later. Installing #{BASELINE_RUBY_2_3} for compatibility", ansi: :yellow
              sh.cmd "rvm install #{BASELINE_RUBY_2_3}"
              sh.cmd "brew_ruby=#{BASELINE_RUBY_2_3}"
            end
            sh.else do
              sh.cmd "brew_ruby=#{first_ruby_2_3_plus}"
            end
            update_homebrew if update_homebrew?
            install_homebrew_packages
          end
        end

        def config
          @config ||= Hash(super)
        end

        private

        def update_homebrew?
          config[:update].to_s.downcase == 'true'
        end

        def update_homebrew
          sh.echo "Updating Homebrew", ansi: :yellow
          sh.cmd "rvm $brew_ruby do brew update 1>/dev/null", echo: true, timing: true
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

        def create_brewfile?
          !(config_taps.empty? && config_casks.empty? && config_packages.empty?)
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

        def user_brewfile?
          config[:brewfile]
        end

        def brew_bundle_args
          if config[:brewfile].to_s.downcase == 'true'
            ''
          else
            " --file=#{Shellwords.escape(config[:brewfile])}"
          end
        end

        def install_homebrew_packages
          sh.echo "Installing Homebrew Packages", ansi: :yellow

          if user_brewfile?
            sh.cmd "rvm $brew_ruby do brew bundle --verbose#{brew_bundle_args}", echo: true, timing: true
          end

          if create_brewfile?
            sh.file '~/.Brewfile', brewfile_contents
            sh.cmd "rvm $brew_ruby do brew bundle --verbose --global", echo: true, timing: true
          end
        end

        def ruby_pre_2_3?
          '-z $(rvm list | grep ruby-2\.[3-9])'
        end

        def first_ruby_2_3_plus
          %q($(rvm list | perl -ne '/ruby-(2\.[3-9][0-9]*(\.[0-9]+)*)/ && print $1,"\n"'| head -1))
        end
      end
    end
  end
end
