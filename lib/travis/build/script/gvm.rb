module Travis
  module Build
    class Script
      module GVM
        def export
          super
          set 'TRAVIS_GO_VERSION', go_version, echo: false
        end

        def setup
          super
          # Yes, install twice.  There's an issue with gvm's `install` behavior.
          # Also, the exit code is nonzero if the version is already installed.
          # No, it is not cool.
          2.times do |n|
            cmd "gvm install #{go_version} || true", fold: "gvm.install.#{n+1}"
          end
          cmd "gvm use #{go_version}"
        end

        def announce
          super
          cmd 'gvm version'
        end

        private

        def go_version
          config[:gvm].to_s
        end
      end
    end
  end
end
