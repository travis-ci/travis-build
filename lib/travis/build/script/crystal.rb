module Travis
  module Build
    class Script
      class Crystal < Script
        DEFAULTS = {
          crystal: 'stable',
        }

        def configure
          super

          sh.fold 'crystal_install' do
            sh.echo 'Installing Crystal', ansi: :yellow

            case config[:os]
            when 'linux'
              validate_crystal_config
              apt_install_crystal
            when 'osx'
              if crystal_config != "latest" && crystal_config != "stable"
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
          super << '-crystal-' << crystal_config
        end

        private

        def crystal_config
          Array(config[:crystal]).first.to_s
        end

        def validate_crystal_config
          # - stable
          # - latest (same as stable, backward compatibility)
          # - unstable
          # - nightly
          # - x.y (from stable channel)
          # - x.y.z (from stable channel)
          # - <channel>/x.y (where <channel> = stable, unstable, nightly)
          # - <channel>/x.y.z (where <channel> = stable, unstable, nightly)
          return if crystal_config == "latest"
          return if crystal_config =~ /\A(stable|unstable|nightly)(\/(\d+)(\.\d+)(\.\d+)?)?/
          return if crystal_config =~ /\A(\d+)(\.\d+)(\.\d+)?/

          sh.failure %Q("#{crystal_config}" is an invalid version of Crystal.\nView valid versions of Crystal at https://docs.travis-ci.com/user/languages/crystal/)
        end

        def apt_install_crystal
          config = crystal_config
          config = "stable" if config == "latest"

          if config =~ /\A(\d+)(\.\d+)(\.\d+)?/
            crystal_channel = "stable"
            crystal_version = config
          else
            crystal_channel, crystal_version = config.split('/')
            crystal_version ||= "latest"
          end

          # Add repo metadata signign key (shared bintray signing key)
          sh.cmd %q(sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 379CE192D401AB61)
          sh.cmd %Q(echo "deb https://dl.bintray.com/crystal/deb all #{crystal_channel}" | sudo tee /etc/apt/sources.list.d/crystal.list)

          sh.cmd 'travis_apt_get_update'
          if crystal_version == "latest"
            sh.cmd %Q(sudo apt-get install -y crystal)
          else
            sh.cmd %Q(sudo apt-get install -y crystal="#{crystal_version}*")
          end
        end

        def cache_dirs
          case config[:os]
          when 'linux'
            %W(
              ${TRAVIS_HOME}/.cache/shards
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
