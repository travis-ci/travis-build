require 'travis/services/vault/keys'
require 'travis/services/vault/connect'

module Travis
  module Vault
    class ConnectionError < StandardError; end
    class RootKeyError < StandardError; end
  end
end
