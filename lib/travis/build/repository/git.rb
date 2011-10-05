module Travis
  module Build
    module Repository
      module Git
        attr_reader :shell

        def initialize(shell, *args)
          @shell = shell
          super(*args)
        end

        def fetch(hash)
          clone
          chdir
          checkout(hash)
        end

        protected

          def clone
            shell.export('GIT_ASKPASS', 'echo', :echo => false) # this makes git interactive auth fail
            shell.execute("git clone --depth=100 --quiet #{source_url} #{target_dir}")
          end

          def chdir
            shell.chdir(target_dir)
          end

          def checkout(hash)
            shell.execute("git checkout -qf #{hash}")
          end
      end
    end
  end
end
