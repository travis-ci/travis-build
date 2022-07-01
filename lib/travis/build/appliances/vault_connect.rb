require 'travis/build/appliances/base'
require 'travis/services/vault'

module Travis
  module Build
    module Appliances
      class VaultConnect < Base
        ERROR_MESSAGE = ["Failed to connect to the Vault instance. Please verify if:\n* The Vault Token is correct. \n* The Vault token is not expired. \n* The Vault can accept connections from the Travis CI build job environments (https://docs.travis-ci.com/user/ip-addresses/).", ansi: :red]
        SUCCESS_MESSAGE = ['Connected to Vault instance.', ansi: :green]

        def apply?
          @vault = config[:vault]
        end

        def apply
          ENV['VAULT_ADDR'] = @vault[:api_url]
          ENV['VAULT_TOKEN'] = @vault[:token]
          ::Vault::Connect.call
          sh.echo *SUCCESS_MESSAGE
        rescue ::Vault::ConnectionError, ArgumentError => _e
          sh.echo *ERROR_MESSAGE
          sh.terminate
        end
      end
    end
  end
end
