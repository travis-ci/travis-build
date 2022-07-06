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
          Travis::Vault::Config.instance.tap do |i|
            i.api_url = @vault[:api_url]
            i.token = @vault[:token]
          end

          Travis::Vault::Connect.call
          sh.echo *SUCCESS_MESSAGE
        rescue Travis::Vault::ConnectionError, ArgumentError, URI::InvalidURIError => _e
          sh.echo *ERROR_MESSAGE
          sh.terminate
        end

      end
    end
  end
end
