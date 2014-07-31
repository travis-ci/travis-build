require 'shellwords'
require 'active_support/core_ext/hash/except'
require 'active_support/core_ext/hash/slice'

module Travis
  module Build
    class Script
      module Addons
        class Deploy
          class Config
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
              on = config[:on] || config[true] || config[:true] || {}
              on = { branch: on.to_str } if on.respond_to?(:to_str)
              on[:ruby] ||= on.delete(:rvm) if on.include?(:rvm)
              on[:node] ||= on.delete(:node_js) if on.include?(:node_js)
              on
            end

            def branches
              config.except(:on).values.grep(Hash).map(&:keys).flatten(1).uniq.compact
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
              options = options.flat_map { |key, value| dpl_option(key, value) }
              options.compact.join(' ')
            end

            private

              def dpl_option(key, value)
                case value
                when Array      then value.map { |v| dpl_option(key, v) }
                when Hash       then dpl_option(key, value[data.branch.to_sym])
                when true       then "--#{key}"
                when nil, false then nil
                else '--%s=%s' % [key, value.to_s.shellescape]
                end
              end
          end
        end
      end
    end
  end
end
