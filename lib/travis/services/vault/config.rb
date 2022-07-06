module Travis
  module Vault
    class Config
      include Singleton

      attr_accessor :api_url, :token
    end
  end
end
