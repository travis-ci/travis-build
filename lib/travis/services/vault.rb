require 'travis/services/vault/keys'
require 'travis/services/vault/connect'

module Travis
  module Vault
    class ConnectionError < StandardError; end
  end
end
