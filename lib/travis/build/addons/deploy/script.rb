require 'travis/build/addons/deploy/conditions'
require 'travis/build/addons/deploy/config'

module Travis
  module Build
    class Addons
      class Deploy < Base
        class Script
          VERSIONED_RUNTIMES = [:jdk, :node, :perl, :php, :python, :ruby, :scala, :go]
          USE_RUBY           = '1.9.3'

          attr_accessor :script, :sh, :data, :config, :allow_failure

          def initialize(script, sh, data, config)
            @script = script
            @sh = sh
            @data = data
            @config = config
            @silent = false
            @allow_failure = config.delete(:allow_failure)
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

          private
            def check_conditions_and_run
              sh.if(conditions) do
                run
              end

              sh.else do
                warning_message_unless(repo_condition, "this repo's name does not match one specified in .travis.yml's deploy.on.repo: #{on[:repo]}")
                warning_message_unless(branch_condition, "this branch is not permitted")
                warning_message_unless(runtime_conditions, "this is not on the required runtime")
                warning_message_unless(custom_conditions, "a custom condition was not met")
                warning_message_unless(tags_condition, "this is not a tagged commit")
              end
            end

            def warning_message_unless(condition, message)
              return if negate_condition(condition) == ""

              sh.if(negate_condition(condition)) { warning_message(message) }
            end

            def on
              @on ||= begin
                on = config.delete(:on) || config.delete(true) || config.delete(:true) || {}
                on = { branch: on.to_str } if on.respond_to? :to_str
                on[:ruby] ||= on[:rvm] if on.include? :rvm
                on[:node] ||= on[:node_js] if on.include? :node_js
                on
              end
            end

            def conditions
              [
                repo_condition,
                branch_condition,
                runtime_conditions,
                custom_conditions,
                tags_condition,
              ].flatten.compact.map { |c| "(#{c})" }.join(" && ")
            end

            def repo_condition
              "$TRAVIS_REPO_SLUG = \"#{on[:repo]}\"" if on[:repo]
            end

            def branch_condition
              return if on[:all_branches] || on[:tags]
              branches  = Array(on[:branch] || default_branches)
              branches.map { |b| "$TRAVIS_BRANCH = #{b}" }.join(' || ')
            end

            def tags_condition
              case on[:tags]
              when true  then '"$TRAVIS_TAG" != ""'
              when false then '"$TRAVIS_TAG" = ""'
              end
            end

            def custom_conditions
              on[:condition]
            end

            def runtime_conditions
              (VERSIONED_RUNTIMES & on.keys).map { |runtime| "$TRAVIS_#{runtime.to_s.upcase}_VERSION = #{on[runtime].to_s.shellescape}" }
            end

            def run
              script.stages.run_stage(:custom, :before_deploy)
              sh.fold('dpl.0') { install }
              cmd(run_command, echo: false, assert: false, timing: true)
              script.stages.run_stage(:custom, :after_deploy)
            end

            def install(edge = config[:edge])
              command = "gem install dpl"
              command << " --pre" if edge
              command << " --local" if edge == 'local'
              cmd(command, echo: false, assert: !allow_failure, timing: true)
            end

            def run_command(assert = !allow_failure)
              return "dpl #{options} --fold" unless assert
              run_command(false) + "; " + die("failed to deploy")
            end

            def die(message)
              'if [ $? -ne 0 ]; then echo %p; travis_terminate 2; fi' % message
            end

            def default_branches
              default_branches = config.values.grep(Hash).map(&:keys).flatten(1).uniq.compact
              default_branches.any? ? default_branches : 'master'
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
              sh.cmd("rvm #{USE_RUBY} --fuzzy do ruby -S #{cmd}", *args)
            end

            def options
              config.flat_map { |k,v| option(k,v) }.compact.join(" ")
            end

            def warning_message(message)
              sh.echo "Skipping a deployment with the #{config[:provider]} provider because #{message}", ansi: :yellow
            end

            def negate_condition(conditions)
              Array(conditions).flatten.compact.map { |condition| " ! #{condition}" }.join(" && ")
            end
        end
      end
    end
  end
end
