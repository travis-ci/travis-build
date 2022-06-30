require 'travis/services/vault/keys'
require 'travis/services/vault/connect'

module Vault
  class ConnectionError < StandardError; end
end