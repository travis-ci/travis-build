require 'shellwords'
require 'active_support/core_ext/hash/except'
require 'active_support/core_ext/hash/slice'
require 'active_support/core_ext/hash/deep_merge'
require 'travis/build/helpers/deprecation'

module Travis
  module Build
    class Addons
      class Deploy < Base
        class Config
          include Deprecation

          RUNTIMES = [:jdk, :node, :perl, :php, :python, :ruby, :scala, :go]

          attr_reader :data, :config

          def initialize(data, config)
            @data = data
            @config = config
          end

          def [](key)
            config[key]
          end

          def edge?
            !!config[:edge]
          end

          def on
            on = config[:if] || config[:on] || config[true] || config[:true] || {}
            on = { branch: on.to_str } if on.respond_to?(:to_str)
            on[:ruby] ||= on.delete(:rvm) if on.include?(:rvm)
            on[:node] ||= on.delete(:node_js) if on.include?(:node_js)
            on
          end

          def branches
            branches = if on[:branch]
              branches = on[:branch]
              branches.is_a?(Hash) ? branches.keys : Array(branches)
            else
              branches = config.except(:on).values.grep(Hash).map(&:keys).flatten(1).uniq.compact
              deprecate DEPRECATED_OPTION_HASHES_SYNTAX if branches.any?
              branches
            end
            branches.any? ? branches : ['master']
          end

          def runtimes
            RUNTIMES & on.keys
          end

          def assert?
            !config[:allow_failure]
          end

          def stages
            config.slice(:before_deploy, :after_deploy)
          end

          def dpl_options
            options = config.except(:edge, :on, true, :true, :allow_failure, :before_deploy, :after_deploy)
            options = options.deep_merge(dpl_branch_options)
            options = options.flat_map { |key, value| dpl_option(key, value) }
            options.compact.join(' ')
          end

          private

            def dpl_branch_options
              on.fetch(:branch, {}).fetch(data.branch.to_sym, {})
            end

            def dpl_option(key, value)
              case value
              when Array      then value.map { |v| dpl_option(key, v) }
              when Hash       then dpl_option(key, value[data.branch.to_sym]).tap { deprecate DEPRECATED_OPTION_HASHES_SYNTAX }
              when true       then "--#{key}"
              when nil, false then nil
              else '--%s=%s' % [key, value.to_s.shellescape]
              end
            end

            DEPRECATED_OPTION_HASHES_SYNTAX = <<-msg
              Using option specific branch hashes is deprecated and will be disabled soon. Please use one of the following syntaxes instead:

              Multiple deployment targets:

                deploy:
                  - provider: s3
                    bucket: production_bucket
                    on:
                      branch: production

                  - provider: s3
                    bucket: staging_bucket
                    on:
                      branch: staging

              Branch specific option hashes:

                deploy:
                  provider: s3
                  on:
                    branch:
                      production:
                        bucket: production_bucket
                      staging:
                        bucket: staging_bucket
            msg
        end
      end
    end
  end
end
