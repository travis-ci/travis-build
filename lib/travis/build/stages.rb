require 'travis/build/stages/addon'
require 'travis/build/stages/base'
require 'travis/build/stages/builtin'
require 'travis/build/stages/custom'
require 'travis/build/stages/conditional'
require 'travis/build/stages/skip'

module Travis
  module Build
    Stage = Struct.new(:type, :name, :run_in_debug)

    class Stages
      STAGES = [
        Stage.new(:builtin,     :setup_filter,   :always),
        Stage.new(:builtin,     :configure,      :always),
        Stage.new(:builtin,     :prepare,        :always),
        Stage.new(:builtin,     :disable_sudo,   :always),
        Stage.new(:builtin,     :checkout,       :always),
        Stage.new(:builtin,     :export,         :always),
        Stage.new(:builtin,     :setup,          :always),
        Stage.new(:builtin,     :setup_casher,   :always),
        Stage.new(:builtin,     :setup_cache,    :always),
        Stage.new(:builtin,     :use_workspaces, :always),
        Stage.new(:builtin,     :announce,       :always),
        Stage.new(:builtin,     :debug,          :always),
        Stage.new(:custom,      :before_install, false),
        Stage.new(:custom,      :install,        false),
        Stage.new(:custom,      :before_script,  false),
        Stage.new(:custom,      :script,         false),
        Stage.new(:custom,      :before_cache,   false),
        Stage.new(:builtin,     :create_workspaces, false),
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
        use_workspaces: { assert: false, echo: true,  timing: true  },
        debug:          { assert: false, echo: true,  timing: true  },
        before_install: { assert: true,  echo: true,  timing: true  },
        install:        { assert: true,  echo: true,  timing: true  },
        before_script:  { assert: true,  echo: true,  timing: true  },
        script:         { assert: false, echo: true,  timing: true  },
        create_workspaces: { assert: false, echo: true,  timing: true },
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

      SKIP_KEYWORDS = %w(
        skip
        ignore
      )

      attr_reader :script, :sh, :config

      def initialize(script, sh, config)
        @script = script
        @sh = sh
        @config = config
      end

      def run
        define_header_stage

        sh.raw "# START_FUNCS"

        STAGES.each do |stage|
          define_stage(stage.type, stage.name)
        end

        sh.raw "# END_FUNCS"

        sh.raw "source ${TRAVIS_HOME}/.travis/job_stages"

        sh.trace_root {
          STAGES.each do |stage|
            case stage.run_in_debug
            when :always
              sh.raw "travis_run_#{stage.name}"
            when true
              sh.raw "travis_run_#{stage.name}" if debug_build?
            when false
              sh.raw "travis_run_#{stage.name}" unless debug_build?
            end
          end
        }
      end

      def define_header_stage
        stage = Travis::Build::Stages::Builtin.new(script, :header)
        commands = stage.run
      end

      def fallback?(type, name)
        type == :custom && !config[name]
      end

      def define_stage(type, name)
        sh.event = name
        sh.raw "cat <<'EOFUNC_#{name.upcase}' >>${TRAVIS_HOME}/.travis/job_stages"
        sh.raw "function travis_run_#{name}() {"
        commands = run_stage(type, name)
        close = (commands.nil? || commands.empty?) ? ":\n}" : "}"
        sh.raw close
        sh.raw "\nEOFUNC_#{name.upcase}"
      end

      def run_stage(type, name)
        type = :builtin if fallback?(type, name)
        type = :skip    if skip?(type, name)
        stage = self.class.const_get(type.to_s.camelize).new(script, name)
        sh.trace(name) {
          stage.run
        }
      end

      def debug_build?
        script.debug_build_via_api?
      end

      def skip?(type, name)
        type != :builtin && SKIP_KEYWORDS.any? { |word| Array(config[name]) == Array(word) }
      end
    end
  end
end
