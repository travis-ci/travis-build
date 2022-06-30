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
          secrets_from_vault = ::Vault::Keys.get(@vault)
        end
      end
    end
  end
end
