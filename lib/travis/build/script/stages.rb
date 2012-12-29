module Travis
  module Build
    class Script
      module Stages
        def run_stages
          STAGES[:builtin].each { |stage| run_builtin_stage(stage) }
          STAGES[:custom].each  { |stage| run_stage(stage) }
        end

        def run_stage(stage)
          if data[stage] && stage != :after_result
            run_custom_stage(stage)
          elsif respond_to?(stage, false) || stage == :after_result # TODO do we really still have that Kernel#install issue with rake?
            run_builtin_stage(stage)
          end
        end

        def run_custom_stage(stage)
          stage(stage) do
            Array(data[stage]).each do |command|
              cmd command
            end
            set_result if stage == :script
          end
        end

        def run_builtin_stage(stage)
          stage(stage) do
            send(stage)
            set_result if stage == :script
          end
        end

        def set_result
          set 'TRAVIS_TEST_RESULT', '$?', echo: false
        end

        def after_result
          self.if('$TRAVIS_TEST_RESULT = 0')  { run_stage(:after_success) } if data[:after_success]
          self.if('$TRAVIS_TEST_RESULT != 0') { run_stage(:after_failure) } if data[:after_failure]
        end

        def stage(stage = nil)
          sh.script &stacking {
            sh.options.update(timeout: timeout_for(stage), assert: assert_stage?(stage))
            raw "travis_start '#{stage}'" if announce?(stage)
            yield
            raw "travis_end '#{stage}'" if announce?(stage)
          }
        end

        def assert_stage?(stage)
          [:setup, :before_install, :install, :before_script].include?(stage)
        end

        def timeout_for(stage)
          data.timeout(stage) if data.timeout?(stage)
        end
      end
    end
  end
end
