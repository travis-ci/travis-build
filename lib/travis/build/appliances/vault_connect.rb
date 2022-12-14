require 'travis/build/appliances/base'
require 'travis/services/vault'

module Travis
  module Build
    module Appliances
      class VaultConnect < Base
        ERROR_MESSAGE = ["Failed to connect to the Vault instance. Please verify if:\n* The Vault Token is correct (encrypted, not plain text). \n* The Vault Token is not expired. \n* The Vault can accept connections from the Travis CI build job environments (https://docs.travis-ci.com/user/ip-addresses/).", ansi: :red].freeze
        SUCCESS_MESSAGE = ['Connected to Vault instance.', ansi: :green].freeze

        def apply?
          @vault = config[:vault] if (config.dig(:vault, :secrets) || []).flatten.any? { |el| el.is_a?(String) }
        end

        def apply
          Travis::Vault::Connect.call(@vault)
          sh.echo *SUCCESS_MESSAGE
          sh.export('VAULT_ADDR', @vault[:api_url], echo: true, secure: true)
          sh.export('VAULT_TOKEN', @vault[:token], echo: true, secure: true)
        rescue Travis::Vault::ConnectionError, ArgumentError, URI::InvalidURIError => _e
          sh.echo *ERROR_MESSAGE
          sh.terminate
        end
      end
    end
  end
end
