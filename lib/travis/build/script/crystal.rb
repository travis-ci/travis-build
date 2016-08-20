module Travis
  module Build
    class Script
      class Crystal < Script

        def configure
          super

          sh.fold 'crystal_install' do
            sh.echo 'Installing Crystal', ansi: :yellow

            version = select_version
            return unless version

            sh.cmd %Q(curl -sSL '#{version[:key][:url]}' > "$HOME/crystal_repository_key.asc")
            sh.if %Q("$(gpg --with-fingerprint "$HOME/crystal_repository_key.asc" | grep "Key fingerprint" | cut -d "=" -f2 | tr -d " ")" != "#{version[:key][:fingerprint]}") do
              sh.failure "The repository key needed to install Crystal did not have the expected fingerprint. Your build was aborted."
            end
            sh.cmd %q(sudo sh -c "apt-key add '$HOME/crystal_repository_key.asc'")

            sh.cmd %Q(sudo sh -c 'echo "deb #{version[:url]} crystal main" > /etc/apt/sources.list.d/crystal-nightly.list')
            sh.cmd %q(sudo sh -c 'apt-get update')
            sh.cmd %Q(sudo apt-get install -y #{version[:package]} libgmp-dev)

            sh.echo 'Installing Shards', ansi: :yellow

            sh.cmd %q(sudo sh -c "curl -sSL https://github.com/crystal-lang/shards/releases/latest | \
                      egrep -o '/crystal-lang/shards/releases/download/v[0-9\.]*/shards.*linux_.*64.gz' | \
                      xargs -Ipath curl -sSL https://github.com/path | \
                      gunzip > /usr/local/bin/shards && \
                      chmod +x /usr/local/bin/shards")
          end
        end

        def setup
          super

          sh.echo 'Crystal for Travis-CI is not officially supported, but is community maintained.', ansi: :green
          sh.echo 'Please file any issues using the following link', ansi: :green
          sh.echo '  https://github.com/travis-ci/travis-ci/issues/new?labels=community:crystal', ansi: :green
          sh.echo 'and mention \`@asterite\`, \`@jhass\`, \`@waj\` and \`@will\` in the issue', ansi: :green
        end

        def announce
          super

          sh.cmd 'crystal --version'
          sh.cmd 'crystal deps --version'
          sh.echo ''
        end

        def install
          sh.if '-f shard.yml' do
            sh.cmd "crystal deps"
          end
        end

        def script
          sh.cmd "crystal spec"
        end

        private

        def select_version
          key = {
            url: "https://dist.crystal-lang.org/rpm/RPM-GPG-KEY",
            fingerprint: "5995C83CD754BE448164192909617FD37CC06B54"
          }

          case config[:crystal]
          when nil, "latest"
            {
              url: "https://dist.crystal-lang.org/apt",
              key: key,
              package: "crystal"
            }
          when "nightly"
            {
              url: "https://nightly.crystal-lang.org/apt",
              key: key,
              package: "crystal-nightly"
            }
          else
            sh.failure %Q("#{config[:crystal]}" is an invalid version of Crystal.\nView valid versions of Crystal at https://docs.travis-ci.com/user/languages/crystal/)
            nil
          end
        end

      end
    end
  end
end
