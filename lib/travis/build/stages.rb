require 'travis/build/stages/addon'
require 'travis/build/stages/base'
require 'travis/build/stages/builtin'
require 'travis/build/stages/custom'
require 'travis/build/stages/conditional'

module Travis
  module Build
    Stage = Struct.new(:type, :name, :run_in_debug)

    class Stages
      STAGES = [
        Stage.new(:builtin,     :configure,      :always),
        Stage.new(:builtin,     :checkout,       :always),
        Stage.new(:builtin,     :prepare,        :always),
        Stage.new(:builtin,     :disable_sudo,   :always),
        Stage.new(:builtin,     :export,         :always),
        Stage.new(:builtin,     :setup,          :always),
        Stage.new(:builtin,     :setup_casher,   :always),
        Stage.new(:builtin,     :setup_cache,    :always),
        Stage.new(:builtin,     :announce,       :always),
        Stage.new(:builtin,     :debug,          :always),
        Stage.new(:custom,      :before_install, false),
        Stage.new(:custom,      :install,        false),
        Stage.new(:custom,      :before_script,  false),
        Stage.new(:custom,      :script,         false),
        Stage.new(:custom,      :before_cache,   false),
        Stage.new(:builtin,     :cache,          false),
        Stage.new(:builtin,     :reset_state,    true),
        Stage.new(:conditional, :after_success,  false),
        Stage.new(:conditional, :after_failure,  false),
        Stage.new(:custom,      :after_script,   false),
        Stage.new(:builtin,     :finish,         :always),
      ]

      STAGE_DEFAULT_OPTIONS = {
        checkout:       { assert: true,  echo: true,  timing: true  },
        export:         { assert: false, echo: false, timing: false },
        setup:          { assert: true,  echo: true,  timing: true  },
        announce:       { assert: false, echo: true,  timing: false },
        setup_casher:   { assert: true,  echo: true,  timing: true  },
        setup_cache:    { assert: true,  echo: true,  timing: true  },
        debug:          { assert: false, echo: true,  timing: true  },
        before_install: { assert: true,  echo: true,  timing: true  },
        install:        { assert: true,  echo: true,  timing: true  },
        before_script:  { assert: true,  echo: true,  timing: true  },
        script:         { assert: false, echo: true,  timing: true  },
        after_success:  { assert: false, echo: true,  timing: true  },
        after_failure:  { assert: false, echo: true,  timing: true  },
        after_script:   { assert: false, echo: true,  timing: true  },
        before_cache:   { assert: false, echo: true,  timing: true  },
        cache:          { assert: false, echo: true,  timing: true  },
        reset_state:    { assert: false, echo: false, timing: false },
        before_deploy:  { assert: true,  echo: true,  timing: true  },
        deploy:         { assert: true,  echo: true,  timing: true  },
        after_deploy:   { assert: false, echo: true,  timing: true  },
        before_finish:  { assert: true,  echo: true,  timing: true  },
        finish:         { assert: true,  echo: true,  timing: true  },
      }

      attr_reader :script, :sh, :config

      def initialize(script, sh, config)
        @script = script
        @sh = sh
        @config = config
      end

      def run
        run_stage(:builtin, :header)

        STAGES.each do |stage|
          run_stage(stage.type, stage.name)
        end

        sh.raw "source $HOME/.build_stages"

        STAGES.each do |stage|
          case stage.run_in_debug
          when :always
            sh.raw "run_stage_#{stage.name}"
          when true
            sh.raw "run_stage_#{stage.name}" if debug_build?
          when false
            sh.raw "run_stage_#{stage.name}" unless debug_build?
          end
        end
      end

      def run_stage(type, name)
        wrap_in_func(name) do
          type = :builtin if fallback?(type, name)
          stage = self.class.const_get(type.to_s.camelize).new(script, name)
          commands = stage.run
        end
      end

      def fallback?(type, name)
        type == :custom && !config[name]
      end

      def wrap_in_func(stage)
        if stage == :header
          yield
        else
          sh.raw "cat <<'EOFUNC' >>$HOME/.build_stages"
          sh.raw "function run_stage_#{stage}() {"
          commands = yield
          close = (commands.nil? || commands.empty?) ? ":\n}" : "}"
          sh.raw close
          sh.raw "EOFUNC"
        end
      end

      def debug_build?
        script.debug_build_via_api?
      end
    end
  end
end
