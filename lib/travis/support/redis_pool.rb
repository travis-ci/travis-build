require 'connection_pool'
require 'redis'

module Travis
  class RedisPool
    attr_reader :pool

    def initialize(options = {})
      pool_options = options.delete(:pool) || {}
      pool_options[:size] ||= 10
      pool_options[:timeout] ||= 10
      @pool = ConnectionPool.new(pool_options) do
        ::Redis.new(options)
      end
    end

    def method_missing(name, *args, &block)
      @pool.with do |redis|
        if redis.respond_to?(name)
          redis.send(name, *args, &block)
        else
          super
        end
      end
    end
  end
end
