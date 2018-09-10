require 'forwardable'

module Travis
  module Build
    class Stages
      class Base < Struct.new(:script, :name)
        extend Forwardable

        def_delegators :script, :sh, :data, :config

        def with_stage(name = nil, &block)
          @stage = name
          options = STAGE_DEFAULT_OPTIONS[name] || {}

          sh.with_options(options || {}, &block)
        end

        def run_addon_stage(name)
          Addon.new(script, name).run
        end

        def result
          sh.raw 'travis_result $?'
        end

        def script?
          name == :script
        end

        def deployment?
          name == :after_success && config[:addons].is_a?(Hash) && !!config[:addons][:deploy]
        end
      end
    end
  end
end
