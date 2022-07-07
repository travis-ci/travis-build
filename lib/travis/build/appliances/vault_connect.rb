require 'travis/build/appliances/base'
require 'travis/services/vault'

module Travis
  module Build
    module Appliances
      class VaultConnect < Base
        ERROR_MESSAGE = ["Failed to connect to the Vault instance. Please verify if:\n* The Vault Token is correct. \n* The Vault token is not expired. \n* The Vault can accept connections from the Travis CI build job environments (https://docs.travis-ci.com/user/ip-addresses/).", ansi: :red].freeze
        SUCCESS_MESSAGE = ['Connected to Vault instance.', ansi: :green].freeze

        def apply?
          @vault = config[:vault]
        end

        def apply
          faraday_connection = Faraday.new(
            url: @vault[:api_url],
            headers: {'X-Vault-Token' => @vault[:token]}
          )

          Travis::Vault::Connect.call(faraday_connection)
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
