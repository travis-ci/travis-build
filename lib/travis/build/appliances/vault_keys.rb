require 'travis/build/appliances/base'
require 'travis/services/vault'

module Travis
  module Build
    module Appliances
      class VaultKeys < Base
        ERROR_MESSAGE = ['Too many keys in fetched data. Probably you provided the root key. Terminating for security reasons.', ansi: :red].freeze

        attr_reader :vault

        class << self
          attr_accessor :already_invoked
        end

        def apply?
          return false if self.class.already_invoked

          @vault = config[:vault] if config.dig(:vault, :secrets).present?
        end

        def apply
          Travis::Vault::Keys.new(self).resolve
          self.class.already_invoked = true
        rescue Travis::Vault::RootKeyError
          sh.echo *ERROR_MESSAGE
          sh.terminate
        end
      end
    end
  end
end
