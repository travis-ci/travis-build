module Travis
  module Build
    class Script
      module Stages
        STAGE_DEFAULT_OPTIONS = {
          checkout:       { assert: true, echo: true, timing: true },
          export:         {},
          setup:          { assert: true, echo: true, timing: true },
          announce:       { echo: true, timing: false },
          before_install: { assert: true, echo: true, timing: true },
          install:        { assert: true, echo: true, timing: true },
          before_script:  { assert: true, echo: true, timing: true },
          script:         { echo: true, timing: true },
          after_result:   { echo: true, timing: true },
          after_script:   { echo: true, timing: true },
          before_deploy:  { assert: true, echo: true, timing: true }
        }

        def run_stages
          STAGES[:builtin].each { |stage| run_builtin_stage(stage) }
          STAGES[:custom].each  { |stage| run_stage(stage) }
        end

        def run_stage(stage)
          if config[stage] && stage != :after_result
            run_custom_stage(stage)
          elsif respond_to?(stage, false) || stage == :after_result
            run_builtin_stage(stage)
          else
            stage(stage) { run_addon_stage(stage) }
          end
        end

        def run_custom_stage(stage)
          stage(stage) do
            run_addon_stage(stage)
            cmds = Array(config[stage])
            cmds.each_with_index do |command, ix|
              sh.cmd command, echo: true, fold: fold_stage?(stage) && "#{stage}#{".#{ix + 1}" if cmds.size > 1}"
              result if stage == :script
            end
          end
        end

        def run_builtin_stage(stage)
          stage(stage) do
            run_addon_stage(stage)
            send(stage)
            result if stage == :script
          end
        end

        def run_addon_stage(stage)
          run_addons(stage)
        end

        def after_result
          run_builtin_stage(:finish)

          if config[:after_success] || deployment?
            sh.if('$TRAVIS_TEST_RESULT = 0') do |sh|
              run_stage(:after_success)
              run_stage(:deploy)
            end
          end

          if config[:after_failure]
            sh.if('$TRAVIS_TEST_RESULT != 0') do |sh|
              run_stage(:after_failure)
            end
          end
        end

        def stage(stage = nil)
          @stage = stage
          sh.options = STAGE_DEFAULT_OPTIONS[stage] || {}
          yield
        end

        def announce?(stage)
          stage && stage != :after_result
        end

        def assert_stage?(stage)
          [:setup, :before_install, :install, :before_script, :before_deploy].include?(stage)
        end

        def result
          sh.cmd 'travis_result $?', echo: false, timing: false
        end

        def fold_stage?(stage)
          stage != :script
        end

        def deployment?
          addons = config.fetch(:addons, {})
          !!addons[:deploy]
        end
      end
    end
  end
end
