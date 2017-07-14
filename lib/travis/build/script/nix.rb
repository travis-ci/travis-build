# Maintained by
#  - Domen Kožar   @domenkozar   <domen@dev.si>
#  - Rok Garbas    @garbas       <rok@garbas.si>
#  - Matthew Bauer @matthewbauer <mjbauer95@gmail.com>

module Travis
  module Build
    class Script
      class Nix < Script
        DEFAULTS = {}

        def export
          super

          # prevent curl from polluting logs but still show errors
          sh.export 'NIX_CURL_FLAGS', '-sS'
        end

        def configure
          super

          # Nix needs to be able to exec on /tmp on Linux
          # This will emit an error in the container but
          # it's still needed for "trusty" Linux.
          if config[:os] == 'linux'
            sh.cmd "sudo mount -o remount,exec /run"
            sh.cmd "sudo mount -o remount,exec /run/user"
          end
        end

        def setup
          super

          sh.fold 'nix.install' do
            sh.if "$TRAVIS_OS_NAME = linux" do
              sh.cmd "sudo mkdir -p -m 0755 /nix/"
              sh.cmd "sudo chown $USER /nix/"
            end

            sh.cmd "wget --retry-connrefused --waitretry=1 -O /tmp/nix-install https://nixos.org/nix/install"
            sh.cmd "yes | sh /tmp/nix-install"

            # Set nix config dir and make config Hydra compatible
            sh.cmd "sed -i.bak '/build-max-jobs/d' /etc/nix/nix.conf"
            sh.cmd "echo 'build-max-jobs = 4' | sudo tee -a /etc/nix/nix.conf > /dev/null"

            # single-user install (linux)
            sh.cmd '[ -e "$HOME/.nix-profile/etc/profile.d/nix.sh"" ] && source $HOME/.nix-profile/etc/profile.d/nix.sh'
            # multi-user install (macos)
            sh.cmd '[ -e "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ] && source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
          end
        end

        def announce
          super

          sh.echo 'Nix support for Travis CI is community maintained.', ansi: :green
          sh.echo 'Please open any issues at https://github.com/travis-ci/travis-ci/issues/new and cc @domenkozar @garbas @matthewbauer', ansi: :green

          sh.cmd "nix-env --version"
        end

        def script
          sh.cmd 'nix-build'
        end
      end
    end
  end
end
