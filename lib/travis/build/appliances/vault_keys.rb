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
          Travis::Vault::Keys.new(@vault, self).resolve
        end
      end
    end
  end
end
