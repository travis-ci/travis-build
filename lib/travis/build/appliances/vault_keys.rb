require 'travis/build/appliances/base'
require 'travis/services/vault'

module Travis
  module Build
    module Appliances
      class VaultKeys < Base

        attr_reader :vault

        def apply?
          @vault = config[:vault] if config.dig(:vault, :secrets).present?
        end

        def apply
          Travis::Vault::Keys.new(self).resolve
        end
      end
    end
  end
end
