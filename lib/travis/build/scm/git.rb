require 'base64'
require 'shellwords'

module Travis
  class Build
    module Scm
      class Git
        extend Assertions

        attr_reader :shell

        def initialize(shell)
          @shell = shell
        end

        def fetch(source, hash, target, config = {})
          copy_key(config['source_key']) if config.key?('source_key')
          clone(source, target)
          chdir(target)
          checkout(hash)
        end

        protected

          def copy_key(key)
            key = Base64.decode64(key)
            shell.execute("cat #{Shellwords.escape(key)} > ~/.ssh/source_rsa", :echo => false)
            shell.execute('ssh-add ~/.ssh/source_rsa', :echo => false)
          end

          def clone(source, target)
            shell.export('GIT_ASKPASS', 'echo', :echo => false) # this makes git interactive auth fail
            shell.execute("git clone --depth=100 --quiet #{source} #{target}")
          ensure
            shell.execute('rm -f ~/.ssh/source_rsa', :echo => false)
          end
          assert :clone

          def chdir(target)
            shell.chdir(target)
          end

          def checkout(hash)
            shell.execute("git checkout -qf #{hash}")
          end
          assert :checkout
      end
    end
  end
end
