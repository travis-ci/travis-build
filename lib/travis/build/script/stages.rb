module Travis
  module Build
    class Script
      class Stages
        STAGE_DEFAULT_OPTIONS = {
          checkout:       { assert: true,  echo: true,  timing: true  },
          export:         { assert: false, echo: false, timing: false },
          setup:          { assert: true,  echo: true,  timing: true  },
          announce:       { assert: false, echo: true,  timing: false },
          before_install: { assert: true,  echo: true,  timing: true  },
          install:        { assert: true,  echo: true,  timing: true  },
          before_script:  { assert: true,  echo: true,  timing: true  },
          script:         { assert: false, echo: true,  timing: true  },
          after_result:   { assert: false, echo: true,  timing: true  },
          after_script:   { assert: false, echo: true,  timing: true  },
          before_deploy:  { assert: true,  echo: true,  timing: true  },
          after_deploy:   { assert: true,  echo: true,  timing: true  }
        }

        attr_reader :script, :sh, :config

        def initialize(script, sh, config)
          @script = script
          @sh = sh
          @config = config
        end

        def run
          STAGES[:builtin].each { |stage| run_builtin_stage(stage) }
          STAGES[:custom].each  { |stage| run_stage(stage) }
          STAGES[:result].each  { |stage| run_result_stage(stage) }
          STAGES[:finish].each  { |stage| run_builtin_stage(stage) }
        end

        def run_stage(stage)
          send(:"run_#{stage_type(stage)}_stage", stage)
        end

        def stage_type(stage)
          type = [:custom, :builtin].detect { |type| send(:"#{type}_stage?", stage) }
          type || :addon
        end

        def custom_stage?(stage)
          config[stage]
        end

        def builtin_stage?(stage)
          script.respond_to?(stage, false)
        end

        def run_custom_stage(stage)
          stage(stage) do
            run_addon_stage(stage) # TODO this should be deprecated. Addons shouldn't mess with user/language stages
            cmds = Array(config[stage])
            cmds.each_with_index do |command, ix|
              sh.cmd command, echo: true, fold: fold_for(stage, cmds, ix)
              result if stage == :script
            end
          end
        end

        def run_builtin_stage(stage)
          stage(stage) do
            run_addon_stage(:"before_#{stage}")
            script.send(stage)
            result if stage == :script
            run_addon_stage(:"after_#{stage}")
          end
        end

        def run_result_stage(stage)
          stage(stage) do
            script.send(stage)
            result if stage == :script
          end
        end

        def run_result_stage(stage)
          if config[stage]
            operator = stage == :after_success ? '=' : '!='
            sh.if("$TRAVIS_TEST_RESULT #{operator} 0") do
              run_custom_stage(stage)
            end
          end
        end

        def run_addon_stage(stage)
          stage(stage) { script.addons.run(stage) } if script.respond_to?(:addons)
        end

        def stage(stage = nil, &block)
          @stage = stage
          sh.with_options(STAGE_DEFAULT_OPTIONS[stage] || {}, &block)
        end

        def result
          sh.raw 'travis_result $?'
        end

        def fold_for(stage, cmds, ix)
          "#{stage}#{".#{ix + 1}" if cmds.size > 1}" if fold_stage?(stage)
        end

        def fold_stage?(stage)
          stage != :script
        end
      end
    end
  end
end
