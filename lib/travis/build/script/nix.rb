# Maintained by
#  - Domen Kožar   @domenkozar   <domen@dev.si>
#  - Rok Garbas    @garbas       <rok@garbas.si>
#  - Matthew Bauer @matthewbauer <mjbauer95@gmail.com>

module Travis
  module Build
    class Script
      class Nix < Script
        DEFAULTS = {
          nix_version: '1.11.2'
        }

        def export
          super

          # prevent curl from polluting logs but still show errors
          sh.export 'NIX_CURL_FLAGS', '-sS'
        end

        def configure
          super

          # Set nix config dir and make config Hydra compatible
          sh.cmd "sudo mkdir -p /etc/nix"
          sh.cmd "echo 'build-max-jobs = 4' | sudo tee /etc/nix/nix.conf"

          # Nix needs to be able to exec on /tmp on Linux
          if config[:os] == 'linux'
            sh.cmd "sudo mount -o remount,exec /run"
            sh.cmd "sudo mount -o remount,exec /run/user"
            sh.cmd "sudo mount"
          end

          # setup /nix dir for rootless install in setup
          sh.cmd "sudo mkdir -p -m 0755 /nix/"
          sh.cmd "sudo chown $USER /nix/"
        end

        def setup
          super

          version = config[:nix_version]

          system = 'x86_64-linux'
          if config[:os] == 'osx'
            system = 'x86_64-darwin'
          end

          # eventually, we should use the .deb provided
          #   but the .tar.bz2 file is the most tested, reliable
          nix_url = "https://nixos.org/releases/nix/nix-#{version}/nix-#{version}-#{system}.tar.bz2"

          sh.cmd "curl -sSL #{nix_url} | bzcat | tar x"
          sh.cmd "./nix-#{version}-#{system}/install"
          sh.cmd "source $HOME/.nix-profile/etc/profile.d/nix.sh"
        end

        def announce
          super

          sh.echo 'Nix support for Travis CI is community maintained.', ansi: :red
          sh.echo 'Please open any issues at https://github.com/travis-ci/travis-ci/issues/new and cc @domen @garbas @matthewbauer', ansi: :red

          sh.cmd "nix-env --version"
        end

        def script
          sh.cmd 'nix-build'
        end
      end
    end
  end
end
