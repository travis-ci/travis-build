module Travis
    module Build
      class Script
        class OCaml < Script
          DEFAULTS = {}
  
          SCRIPT_MISSING = 'Please override the script: key in your .travis.yml to run tests.'
  
          def export
            super
          end
  
          def configure
            super
            sh.cmd 'sudo apt-get update -qq'
            sh.cmd 'sudo apt-get -y install ocaml'
          end
  
          def setup
            super
          end
  
          def announce
            sh.cmd 'ocaml --version'
            sh.cmd 'opam --version'
          end
  
          def setup_cache
            
          end
  
          def install
            
          end
  
          def script
            sh.failure SCRIPT_MISSING
          end
  
          def cache_slug
            super << '--ocaml-' << version
          end
  
          def use_directory_cache?
            super
          end

        end
      end
    end
  end
  