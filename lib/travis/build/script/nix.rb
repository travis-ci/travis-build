# Maintained by
#  - Domen Kožar        @domenkozar   <domen@dev.si>
#  - Rok Garbas         @garbas       <rok@garbas.si>
#  - Matthew Bauer      @matthewbauer <mjbauer95@gmail.com>
#  - Graham Christensen @grahamc      <graham@grahamc.com>

module Travis
  module Build
    class Script
      class Nix < Script
        DEFAULTS = {
          nix: '2.3.6'
        }

        def export
          super

          # prevent curl from polluting logs but still show errors
          sh.export 'NIX_CURL_FLAGS', '-sS'
        end

        def configure
          super

          sh.cmd "echo '-s' >> ~/.curlrc"
          sh.cmd "echo '-S' >> ~/.curlrc"
          sh.cmd "echo '--retry 3' >> ~/.curlrc"

          # Nix needs to be able to exec on /tmp on Linux
          # This will emit an error in the container but
          # it's still needed for "trusty" Linux.
          if config[:os] == 'linux'
            sh.cmd "sudo mount -o remount,exec /run"
            sh.cmd "sudo mount -o remount,exec /run/user"
            sh.cmd "echo 'build-max-jobs = 4' | sudo tee /tmp/nix.conf > /dev/null"
          end
        end

        def setup
          super

          sh.fold 'nix.install' do
            sh.cmd "wget --retry-connrefused --waitretry=1 -O /tmp/nix-install https://releases.nixos.org/nix/nix-#{config[:nix]}/install"
            sh.cmd "yes | sh /tmp/nix-install --daemon --nix-extra-conf-file /tmp/nix.conf"

            sh.cmd 'source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
          end
        end

        def announce
          super

          sh.echo 'Nix support for Travis CI is community maintained.', ansi: :green
          sh.echo 'Please open any issues at https://travis-ci.community/c/languages/nix and cc @domenkozar @garbas @matthewbauer @grahamc', ansi: :green

          sh.cmd "nix-env --version"
          sh.cmd "nix-instantiate --eval -E 'with import <nixpkgs> {}; lib.version or lib.nixpkgsVersion'"
        end

        def script
          sh.cmd 'nix-build'
        end
      end
    end
  end
end
