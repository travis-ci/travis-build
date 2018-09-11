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
            max_size: Float(1024 * 1024 * 50)
          }

          attr_reader :data, :env

          def initialize(data, config)
            @data = data
            @env = env_from_config(config)
          end

          def each(&block)
            env.each(&block)
          end

          def force?(key)
            force_keys.include?(key) || !key.start_with?('ARTIFACTS_')
          end

          private

            def env_from_config(config_hash)
              config_hash.dup.each do |k, v|
                config_hash[k.to_s.gsub(/-/, '_')] = config_hash.delete(k)
              end

              ret_hash = DEFAULT
                .merge(target_paths: target_paths)
                .merge(config_hash.deep_symbolize_keys)
                .merge(FORCE)

              ret_arr = ret_hash.map do |key, value|
                [to_key(key), to_value(value)]
              end

              Hash[*(['PATH', '${TRAVIS_HOME}/bin:$PATH'] + ret_arr).flatten]
            end

            def target_paths
              [data.slug, data.build[:number], data.job[:number]].join('/')
            end

            def force_keys
              @force_keys ||= FORCE.keys.map { |k| to_key(k) }
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
