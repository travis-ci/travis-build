require 'travis/build/appliances/base'
require 'travis/services/vault'

module Travis
  module Build
    module Appliances
      class VaultKeys < Base
        def apply?
          @vault = config[:vault]
        end

        def apply
          ::Vault::Keys.get(@vault, self)
        end
      end
    end
  end
end
