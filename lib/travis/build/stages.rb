require 'travis/build/stages/addon'
require 'travis/build/stages/base'
require 'travis/build/stages/builtin'
require 'travis/build/stages/custom'
require 'travis/build/stages/conditional'

module Travis
  module Build
    class Stages
      STAGES = [
        :builtin,     [:header, :configure, :checkout, :prepare, :disable_sudo, :export, :setup, :setup_casher, :setup_cache, :announce, :debug],
        :custom,      [:before_install, :install, :before_script, :script, :before_cache],
        :builtin,     [:cache, :reset_state],
        :conditional, [:after_success],
        # :addon,       [:deploy_all],
        :conditional, [:after_failure],
        :custom,      [:after_script],
        :builtin,     [:finish]
      ]

      STAGES_DEBUG = [
        :builtin,     [:header, :configure, :checkout, :prepare, :disable_sudo, :export, :setup, :setup_casher, :setup_cache, :announce, :debug],
        :builtin,     [:reset_state],
        :builtin,     [:finish]
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
        stages.each_slice(2) do |type, names|
          names.each { |name| run_stage(type, name) }
        end
      end

      def stages
        script.debug_build_via_api? ? STAGES_DEBUG : STAGES
      end

      def run_stage(type, name)
        type = :builtin if fallback?(type, name)
        stage = self.class.const_get(type.to_s.camelize).new(script, name)
        stage.run
      end

      def fallback?(type, name)
        type == :custom && !config[name]
      end
    end
  end
end
