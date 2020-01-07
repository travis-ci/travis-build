module Travis
  module Build
    class Script
      class Crystal < Script

        def configure
          super

          sh.fold 'crystal_install' do
            sh.echo 'Installing Crystal', ansi: :yellow

            case config[:os]
            when 'linux'
              validate_version
              if config[:crystal] == 'nightly'
                snap_install_crystal '--channel=latest/edge'
              else
                snap_install_crystal '--channel=latest/stable'
              end
            when 'osx'
              if config[:crystal] && config[:crystal] != "latest"
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

        private

        def validate_version
          if config[:crystal] != 'latest' && config[:crystal] != 'nightly' && !config[:crystal].nil?
            sh.failure %Q("#{config[:crystal]}" is an invalid version of Crystal.\nView valid versions of Crystal at https://docs.travis-ci.com/user/languages/crystal/)
          end
        end

        def snap_install_crystal(options)
          sh.if '"$TRAVIS_DIST" == precise || "$TRAVIS_DIST" == trusty' do
            sh.failure "Crystal will only be supported on Xenial or later releases"
          end
          sh.cmd %Q(sudo apt-get install -y gcc pkg-config git tzdata libpcre3-dev libevent-dev libyaml-dev libgmp-dev libssl-dev libxml2-dev)
          sh.cmd %Q(sudo snap install crystal --classic #{options})
        end
      end
    end
  end
end
