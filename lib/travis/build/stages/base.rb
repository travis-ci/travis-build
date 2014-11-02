require 'forwardable'

module Travis
  module Build
    class Stages
      class Base < Struct.new(:script, :name)
        extend Forwardable

        def_delegators :script, :sh, :data, :config

        def with_stage(name = nil, &block)
          @stage = name
          sh.with_options(STAGE_DEFAULT_OPTIONS[name] || {}, &block)
        end

        def result
          sh.raw 'travis_result $?'
        end

        def script?
          name == :script
        end
      end
    end
  end
end
