module Travis
  module Build
    class Script
      class Crystal < Script

        def configure
          super

          sh.fold 'crystal_install' do
            sh.echo 'Installing Crystal', ansi: :yellow

            sh.cmd %q(sudo sh -c 'apt-key adv --keyserver keys.gnupg.net --recv-keys 09617FD37CC06B54')

            version = select_version
            return unless version

            sh.cmd %Q(sudo sh -c 'echo "deb #{version[:url]} crystal main" > /etc/apt/sources.list.d/crystal-nightly.list')
            sh.cmd %q(sudo sh -c 'apt-get update')
            sh.cmd %Q(sudo apt-get install #{version[:package]})

            sh.echo 'Installing Shards', ansi: :yellow

            sh.cmd %q(sudo sh -c "curl -sL https://github.com/ysbaddaden/shards/releases/latest | \
                      egrep -o '/ysbaddaden/shards/releases/download/v[0-9\.]*/shards.*linux_.*64.gz' | \
                      wget --base=http://github.com/ -i - -O - | \
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
          case config[:crystal]
          when nil, "latest"
            {
              url: "http://dist.crystal-lang.org/apt",
              package: "crystal"
            }
          when "nightly"
            {
              url: "http://nightly.crystal-lang.org/apt",
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
