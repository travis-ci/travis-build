module Travis
  class Build
    module Scm
      class Git
        extend Assertions

        attr_reader :shell

        def initialize(shell)
          @shell = shell
        end

        def fetch(source, hash, target)
          clone(source, target)
          chdir(target)
          checkout(hash)
        end

        protected

          def clone(source, target)
            shell.export('GIT_ASKPASS', 'echo', :echo => false) # this makes git interactive auth fail
            shell.execute("git clone --depth=100 --quiet #{source} #{target}")
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
