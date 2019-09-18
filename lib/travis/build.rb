require 'travis/support'
require 'travis/support/redis_pool'

module Travis
  module Build
    autoload :Config, 'travis/build/config'
    autoload :Bash, 'travis/build/bash'

    HOME_DIR  = '${HOME}'
    BUILD_DIR = File.join(HOME_DIR, 'build')

    def config
      @config ||= ::Travis::Build::Config.load
    end

    module_function :config

    def top
      @top ||= Pathname.new(
        `git rev-parse --show-toplevel 2>/dev/null`.strip
      )
    end

    module_function :top

    class << self
      def version
        return @version if @version
        @version ||= `git describe --always --dirty --tags 2>/dev/null`.strip
        @version = nil unless $?.success?
        @version ||= ENV.fetch('HEROKU_SLUG_COMMIT', nil)
        @version ||= top.join('VERSION').read if top.join('VERSION').exist?
        @version ||= 'unknown'
        @version
      end

      def self.register(key)
        Travis.services.add(key, self)
      end

      def script(data)
        data  = data.deep_symbolize_keys
        lang  = (Array(data[:config][:language]).first || 'ruby').to_s.downcase.strip
        const = by_lang(lang)
        const.new(data)
      end

      def by_lang(lang)
        case lang
        when /^java/i then
          Script::PureJava
        when "c++", "cpp", "cplusplus" then
          Script::Cpp
        when 'objective-c', 'swift' then
          Script::ObjectiveC
        when 'bash', 'sh', 'shell', 'minimal' then
          Script::Generic
        else
          name = lang.split('_').map { |w| w.capitalize }.join
          Script.const_get(name, false) rescue Script::Ruby
        end
      end

      def redis
        @redis = Travis::RedisPool.new(config.redis.to_h)
      end

      def logger
        @logger ||= Travis::Logger.configure(Logger.new(STDOUT))
      end

      attr_writer :logger
    end
  end
end

require 'core_ext/hash/deep_symbolize_keys'
require 'core_ext/string/output_safe'
require 'travis/shell'
require 'travis/build/data'
require 'travis/build/env'
require 'travis/build/script'
