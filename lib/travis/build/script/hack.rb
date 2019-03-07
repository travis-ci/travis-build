module Travis
  module Build
    class Script
      class Hack < Php
        DEFAULTS = {
          hhvm: 'hhvm' # lts
        }

        VALID_HHVM = %w(
          hhvm
          hhvm-dbb
          hhvm-nightly
          hhvm-nightly-dbg
          hhvm-dev-nightly
        )

        def configure
          super
        end

        def export
          super
        end

        def setup

        end

        def announce
          sh.cmd 'hhvm --version'
        end

        def install

        end

        def script

        end

        def hhvm?
          unless VALID_HHVM.include? version
            sh.echo "hhvm version given #{version}"
            sh.failure "hhvm version must be one of: #{VALID_HHVM.join(", ")}."
          end
          true
        end

        def version
          Array(config[:hhvm]).first.to_s
        end

        def cache_slug
          (super << "--hack-" << version).gsub(/--php-[^-]+/,'')
        end

      end
    end
  end
end
