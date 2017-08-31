require 'travis/build/addons/conditional'

module Travis
  module Build
    class Addons
      class Deploy < Base
        class Script
          attr_accessor :script, :sh, :data, :config, :conditional, :allow_failure

          def initialize(script, sh, data, config)
            @script = script
            @sh = sh
            @data = data
            @config = config
            @silent = false

            @allow_failure = config.delete(:allow_failure)

            @conditional = Travis::Build::Addons::Conditional.new(sh, self, config)

          rescue
            raise Travis::Build::DeployConfigError.new
          end

          def deploy
            if data.pull_request
              warning_message "the current build is a pull request."
              return
            end

            if conditions.empty?
              run
            else
              check_conditions_and_run
            end
          end

          def warning_message_template
            "Skipping a deployment with the #{config[:provider]} provider because " + '%s'
          end

          private
            def check_conditions_and_run
              sh.if(conditions) do
                run
              end

              sh.else do
                conditional.warning_messages
              end
            end

            def conditions
              conditional.conditions
            end

            def run
              sh.with_errexit_off do
                script.stages.run_stage(:custom, :before_deploy)
                sh.fold('dpl.0') { install }
                cmd(run_command, echo: false, assert: false, timing: true)
                script.stages.run_stage(:custom, :after_deploy)
              end
            end

            def install(edge = config[:edge])
              edge = config[:edge]
              if edge.respond_to? :fetch
                src = edge.fetch(:source, 'travis-ci/dpl')
                branch = edge.fetch(:branch, 'master')
                build_gem_locally_from(src, branch)
              end
              command = "gem install dpl"
              command << "-*.gem --local" if edge == 'local' || edge.respond_to?(:fetch)
              command << " --pre" if edge
              cmd(command, echo: false, assert: !allow_failure, timing: true)
              sh.cmd "rm -f dpl-*.gem", echo: false, assert: false, timing: false
            end

            def run_command(assert = !allow_failure)
              return "dpl #{options} --fold" unless assert
              run_command(false) + "; " + die("failed to deploy")
            end

            def die(message)
              'if [ $? -ne 0 ]; then echo %p; travis_terminate 2; fi' % message
            end

            def option(key, value)
              case value
              when Array      then value.map { |v| option(key, v) }
              when Hash       then option(key, value[data.branch.to_sym])
              when true       then "--#{key}"
              when nil, false then nil
              else "--%s=%p" % [key, value]
              end
            end

            def cmd(cmd, *args)
              sh.cmd('type rvm &>/dev/null || source ~/.rvm/scripts/rvm', echo: false, assert: false)
              sh.cmd("rvm $(travis_internal_ruby) --fuzzy do ruby -S #{cmd}", *args)
            end

            def options
              config.flat_map { |k,v| option(k,v) }.compact.join(" ")
            end

            def build_gem_locally_from(source, branch)
              sh.echo "Building dpl gem locally with source #{source} and branch #{branch}", ansi: :yellow
              sh.cmd("gem uninstall -a -x dpl >& /dev/null",                echo: false, assert: !allow_failure, timing: false)
              sh.cmd("pushd /tmp >& /dev/null",                             echo: false, assert: !allow_failure, timing: true)
              sh.cmd("git clone https://github.com/#{source} #{source}",    echo: true,  assert: !allow_failure, timing: true)
              sh.cmd("pushd #{source} >& /dev/null",                        echo: false, assert: !allow_failure, timing: true)
              sh.cmd("git checkout #{branch}",                              echo: true,  assert: !allow_failure, timing: true)
              sh.cmd("git show-ref -s HEAD",                                echo: true,  assert: !allow_failure, timing: true)
              cmd("gem build dpl.gemspec",                                  echo: true,  assert: !allow_failure, timing: true)
              sh.cmd("mv dpl-*.gem $TRAVIS_BUILD_DIR >& /dev/null",         echo: false, assert: !allow_failure, timing: true)
              sh.cmd("popd >& /dev/null",                                   echo: false, assert: !allow_failure, timing: true)
              # clean up, so that multiple edge providers can be run
              sh.cmd("rm -rf $(dirname #{source})",                         echo: false, assert: !allow_failure, timing: true)
              sh.cmd("popd >& /dev/null",                                   echo: false, assert: !allow_failure, timing: true)
            ensure
              sh.cmd("test -e /tmp/dpl && rm -rf dpl", echo: false, assert: false, timing: true)
            end
        end
      end
    end
  end
end
