module Travis
  module Build
    class Script
      class Crystal < Script
        DEFAULTS = {
          crystal: 'latest',
        }

        def configure
          super

          sh.fold 'crystal_install' do
            sh.echo 'Installing Crystal', ansi: :yellow

            case config[:os]
            when 'linux'
              validate_version
              if crystal_config_version == 'nightly'
                linux_nightly
              else
                linux_latest
              end
            when 'osx'
              if crystal_config_version != "latest"
                sh.failure %Q(Specifying Crystal version is not yet supported by the macOS environment)
              end
              sh.cmd %q(brew update)
              sh.cmd %q(brew install crystal-lang)
            else
              sh.failure %Q(Operating system not supported: "#{config[:os]}")
            end
          end
        end

        def setup
          super

          sh.echo 'Crystal for Travis-CI is not officially supported, but is community maintained.', ansi: :green
          sh.echo 'Please file any issues using the following link', ansi: :green
          sh.echo '  https://travis-ci.community/c/languages/crystal', ansi: :green
          sh.echo 'and mention \`@jhass\`, \`@bcardiff\`, \`@waj\` and \`@will\` in the issue', ansi: :green
        end

        def announce
          super

          sh.cmd 'crystal --version'
          sh.cmd 'shards --version'
          sh.newline
        end

        def install
          sh.if '-f shard.yml' do
            sh.cmd "shards install"
          end
        end

        def script
          sh.cmd "crystal spec"
        end

        def setup_cache
          if data.cache?(:shards) && !cache_dirs.empty?
            sh.fold 'cache.shards' do
              directory_cache.add cache_dirs
            end
          end
        end

        def cache_slug
          super << '-crystal-' << crystal_config_version
        end

        private

        def crystal_config_version
          Array(config[:crystal]).first.to_s
        end

        def validate_version
          if crystal_config_version != 'latest' && crystal_config_version != 'nightly'
            sh.failure %Q("#{crystal_config_version}" is an invalid version of Crystal.\nView valid versions of Crystal at https://docs.travis-ci.com/user/languages/crystal/)
          end
        end

        def linux_latest
          sh.if "-n $(command -v snap)" do
            snap_install_crystal '--channel=latest/stable'
          end
          sh.else do
            apt_install_crystal
          end
        end

        def linux_nightly
          sh.if "-n $(command -v snap)" do
            snap_install_crystal '--channel=latest/edge'
          end
          sh.else do
            sh.failure "Crystal nightlies will only be supported via snap. Use Xenial or later releases."
          end
        end

        def snap_install_crystal(options)
          sh.cmd %Q(sudo apt-get install -y gcc pkg-config git tzdata libpcre3-dev libevent-dev libyaml-dev libgmp-dev libssl-dev libxml2-dev 2>&1 > /dev/null), echo: true
          sh.cmd %Q(sudo snap install crystal --classic #{options}), echo: true
        end

        def apt_install_crystal
          version = {
            url: "https://dist.crystal-lang.org/apt",
            key: {
              url: "https://dist.crystal-lang.org/rpm/RPM-GPG-KEY",
              fingerprint: "5995C83CD754BE448164192909617FD37CC06B54"
            },
            package: "crystal"
          }

          sh.cmd %Q(curl -sSL '#{version[:key][:url]}' > "${TRAVIS_HOME}/crystal_repository_key.asc")
          sh.if %Q("$(gpg --with-fingerprint "${TRAVIS_HOME}/crystal_repository_key.asc" | grep "Key fingerprint" | cut -d "=" -f2 | tr -d " ")" != "#{version[:key][:fingerprint]}") do
            sh.failure "The repository key needed to install Crystal did not have the expected fingerprint. Your build was aborted."
          end
          sh.cmd %q(sudo sh -c "apt-key add '${TRAVIS_HOME}/crystal_repository_key.asc'")

          sh.cmd %Q(sudo sh -c 'echo "deb #{version[:url]} crystal main" > /etc/apt/sources.list.d/crystal-nightly.list')
          sh.cmd 'travis_apt_get_update'
          sh.cmd %Q(sudo apt-get install -y #{version[:package]} libgmp-dev)
        end

        def cache_dirs
          case config[:os]
          when 'linux'
            %W(
              ${TRAVIS_HOME}/.cache/shards
              ${TRAVIS_HOME}/snap/crystal/common/.cache/shards
            )
          when 'osx'
            %W(
              ${TRAVIS_HOME}/.cache/shards
            )
          else
            []
          end
        end
      end
    end
  end
end
