require 'travis/build/addons/apt'

module Travis
  module Build
    class Addons
      class AptPackages
        SUPER_USER_SAFE = true

        class << self
          def new(script, sh, data, config)
            ::Travis::Build::Addons::Apt.new(script, sh, data, { packages: config })
          end
        end
      end
    end
  end
end
