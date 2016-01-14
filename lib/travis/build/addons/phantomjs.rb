require 'shellwords'
require 'travis/build/addons/base'

module Travis
  module Build
    class Addons
      class PhantomJs < Base
        SUPER_USER_SAFE = true

        attr_reader :version

        def after_prepare
          sh.fold 'install_phantomjs' do
            sanitize(raw_version)

            unless version
              sh.echo "Invalid version '#{raw_version}' given. Only 1.9.8 and 2.0.0 are supported at the moment", ansi: :red
              return
            end

            sh.echo "Installing PhantomJS #{version}", ansi: :yellow

            sh.if "$(uname) = 'Linux'" do
              sh.if "$(lsb_release -c) = 'precise'" do
                if version == '2.0.0'
                  sh.mkdir "/tmp/travis-phantomjs"
                  sh.cmd "wget https://s3.amazonaws.com/travis-phantomjs/phantomjs-2.0.0-ubuntu-12.04.tar.bz2 -O /tmp/travis-phantomjs/phantomjs-2.0.0-ubuntu-12.04.tar.bz2", echo: true, timing: true, retry: true
                  sh.cmd "tar -xvf /tmp/travis-phantomjs/phantomjs-2.0.0-ubuntu-12.04.tar.bz2 -C /tmp/travis-phantomjs", echo: true, timing: true, retry: false
                  sh.export "PATH", "/tmp/travis-phantomjs:$PATH"
                else
                  # no need to do anything for 1.9.8 at the moment, it's the
                  # default on precise
                end
              end

              sh.else do
                if version == '1.9.8'
                  sh.mkdir "/tmp/travis-phantomjs"
                  sh.cmd "wget https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-1.9.8-linux-x86_64.tar.bz2 -O /tmp/travis-phantomjs/phantomjs-1.9.8-linux-x86_64.tar.bz2", echo: true, timing: true, retry: true
                  sh.cmd "tar -xvf /tmp/travis-phantomjs/phantomjs-1.9.8-linux-x86_64.tar.bz2 -C /tmp/travis-phantomjs", echo: true, timing: true, retry: false
                  sh.export "PATH", "/tmp/travis-phantomjs/phantomjs-1.9.8-linux-x86_64/bin/:$PATH"
                else
                  sh.cmd "sudo add-apt-repository ppa:tanguy-patte/phantomjs -y", echo: true, timing: true, retry: true
                  sh.cmd "sudo apt-get update", echo: true, timing: true, retry: true
                  sh.cmd "sudo apt-get install phantomjs", echo: true, timing: true, retry: true
                end
              end
            end

            sh.else do
              sh.mkdir "/tmp/travis-phantomjs"
              sh.cmd "wget https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-#{version}-macosx.zip -O /tmp/travis-phantomjs/phantomjs-#{version}-macosx.zip", echo: true, timing: true, retry: true
              sh.cmd "unzip /tmp/travis-phantomjs/phantomjs-#{version}-macosx.zip -d /tmp/travis-phantomjs", echo: true, timing: true
              sh.export "PATH", "/tmp/travis-phantomjs/phantomjs-#{version}-macosx/bin:$PATH"
            end
          end
        end

        private
          def raw_version
            config.to_s.strip.shellescape
          end

          def sanitize(input)
            if m = /\A(1.9.8|2.0.0)\z/.match(input.chomp)
              @version = m[0]
            end
          end
      end
    end
  end
end
