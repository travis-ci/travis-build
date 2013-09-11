module Travis
  module Build
    class Script
      module DirectoryCache
        class S3
          # TODO: Switch to different branch from master?
          CASHER_URL = "https://raw.github.com/rkh/casher/master/bin/casher"

          def initialize(options)
          end

          def install(sh)
            sh.cmd "export CASHER_DIR=$HOME/.casher", log: false, echo: false
            sh.cmd "mkdir -p $CASHER_DIR/bin", log: false, echo: false
            sh.cmd "curl #{CASHER_URL} -o #{binary}", echo: false
            sh.cmd "chmod +x #{binary}", log: false, echo: false
          end

          def add(sh, path)
            run(sh, "add", path)
          end

          def fetch(sh)
            run(sh, "fetch", fetch_url)
          end

          def fetch_url
            raise NotImplementedError
          end

          def push_url
            raise NotImplementedError
          end

          private

            def binary
              "$CASHER_DIR/bin/casher"
            end

            def run(sh, command, argument)
              sh.cmd("#{binary} #{command} #{argument}")
            end
        end

        class Dummy
          def method_missing(*)
            self
          end
        end

        def directory_cache
          @directory_cache ||= data.config[:cache_directories] ? S3.new(data.cache_options) : Dummy.new
        end

        def setup_directory_cache
          directory_cache.install(self)
          directory_cache.fetch(self)
          Array(data.config[:cache_directories]).each do |entry|
            directory_cache.add(self, entry) if entry.is_a? String
          end
        end
      end
    end
  end
end
