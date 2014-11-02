require 'travis/build/script/addons/deploy/conditions'
require 'travis/build/script/addons/deploy/config'

module Travis
  module Build
    class Script
      class Addons
        class Deploy < Base
          class Script
            USE_RUBY = '1.9.3'

            attr_accessor :sh, :data, :config, :conditions

            def initialize(sh, data, config)
              @sh = sh
              @data = data
              @config = Config.new(data, config)
              @conditions = Conditions.new(self.config)
            end

            def deploy
              sh.if(conditions.to_s) do
                stage(:before_deploy)
                run
                stage(:after_deploy)
              end

              sh.else do
                conditions.each_with_message(negate: true) do |condition, message|
                  sh.if(condition) { failure_message(message) } if condition
                end
              end
            end

            private

              def stage(name)
                Array(config.stages[name]).each do |cmd|
                  sh.cmd cmd, echo: true, assert: true, timing: true
                end
              end

              def run
                sh.fold 'dpl.0' do
                  install
                end

                rvm_cmd "dpl #{config.dpl_options} --fold", assert: config.assert?, timing: true
                sh.if('$? -ne 0') do
                  sh.echo 'Failed to deploy.', ansi: :red
                  sh.cmd 'travis_terminate 2', echo: false, timing: false if config.assert?
                end
              end

              def install(edge = config[:edge])
                command = 'gem install dpl'
                command << " --pre" if edge
                command << " --local" if edge == 'local'
                rvm_cmd command, echo: false, assert: config.assert?, timing: true
              end

              def rvm_cmd(cmd, *args)
                sh.cmd("rvm #{USE_RUBY} --fuzzy do ruby -S #{cmd}", *args)
              end

              def failure_message(message)
                sh.echo "Skipping deployment with the #{config[:provider]} provider because #{message}.", ansi: :red
              end
          end
        end
      end
    end
  end
end
