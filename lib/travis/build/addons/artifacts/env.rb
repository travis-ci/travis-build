require 'core_ext/hash/deep_symbolize_keys'
require 'active_support/core_ext/hash/slice'

module Travis
  module Build
    class Addons
      class Artifacts < Base
        class Env
          DEFAULT = {
            paths: '$(git ls-files -o | tr "\n" ":")',
            log_format: 'multiline'
          }

          FORCE = {
            concurrency: 5,
            max_size: Float(1024 * 1024 * 50),
            target_paths: nil
          }

          KEYS = [:key, :secret, :bucket, :private, *DEFAULT.keys, *FORCE.keys]

          attr_reader :data, :env

          def initialize(data, env)
            @data = data
            @env = normalize(env)
          end

          def each(&block)
            env.each(&block)
          end

          private

            def normalize(env)
              env = DEFAULT.merge(env.deep_symbolize_keys)
              env = env.merge(FORCE.merge(target_paths: target_paths))
              env = env.slice(*KEYS)
              env = env.map { |key, value| [to_key(key), to_value(value)] }
              env = ['PATH', '$HOME/bin:$PATH'] + env
              env = Hash[*env.flatten]
            end

            def target_paths
              [data.slug, data.build[:number], data.job[:number]].join('/')
            end

            def to_key(key)
              "ARTIFACTS_#{key.to_s.upcase}"
            end

            def to_value(value)
              [value].flatten.map(&:to_s).join(':')
            end
        end
      end
    end
  end
end
