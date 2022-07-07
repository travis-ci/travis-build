require 'travis/build/appliances/base'
require 'travis/services/vault'

module Travis
  module Build
    module Appliances
      class VaultKeys < Base
        ERROR_MESSAGE = ['Too many keys in fetched data. Probably you provided the root key. Terminating for security reasons.', ansi: :red].freeze

        attr_reader :vault

        def apply?
          @vault = config[:vault] if config.dig(:vault, :secrets).present?
        end

        def apply
          Travis::Vault::Keys.new(self).resolve
        rescue Travis::Vault::RootKeyError
          sh.echo *ERROR_MESSAGE
          sh.terminate
        end
      end
    end
  end
end
