module Travis
  module Build
    class Script
      module Addons
        class Deploy
          class Provider
            VERSIONED_RUNTIMES = [:jdk, :node, :perl, :php, :python, :ruby, :scala, :go]
            USE_RUBY           = '1.9.3'

            attr_accessor :script, :sh, :data, :config, :allow_failure

            def initialize(script, config)
              @silent = false
              @script = script
              @sh = script.sh
              @data = script.data
              @config = config
              @assert = !config.delete(:allow_failure)
            end

            def deploy
              if data.pull_request
                failure_message "the current build is a pull request"
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
                  script.run_stage(:before_deploy)
                  run
                  script.run_stage(:after_deploy)
                end

                sh.else do
                  failure_message_unless(repo_condition, "this is a forked repo")
                  failure_message_unless(branch_condition, "this branch is not permitted deploy")
                  failure_message_unless(runtime_conditions, "this is not on the required runtime")
                  failure_message_unless(custom_conditions, "a custom condition was not met")
                  failure_message_unless(tags_condition, "this is not a tagged commit")
                end
              end

              def failure_message_unless(condition, message)
                condition = negate(condition)
                sh.if(condition) { failure_message(message) } if condition
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
                return if on[:all_branches]
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
                runtimes = (VERSIONED_RUNTIMES & on.keys)
                runtimes.map { |runtime| "$TRAVIS_#{runtime.to_s.upcase}_VERSION = #{on[runtime].shellescape}" }
              end

              def run
                sh.fold 'dpl.0' do
                  install
                end

                rvm_cmd "dpl #{options} --fold", assert: assert?, timing: true
                sh.if('$? -ne 0') do
                  sh.echo 'Failed to deploy.', ansi: :red
                  sh.cmd 'travis_terminate 2', echo: false, timing: false if assert?
                end
              end

              def install(edge = config[:edge])
                command = "gem install dpl"
                command << " --pre" if edge
                rvm_cmd command, echo: false, assert: assert?, timing: true
              end

              def rvm_cmd(cmd, *args)
                sh.cmd("rvm #{USE_RUBY} --fuzzy do ruby -S #{cmd}", *args)
              end

              def assert?
                @assert
              end

              def default_branches
                branches = config.values.grep(Hash).map(&:keys).flatten(1).uniq.compact
                branches.any? ? branches : 'master'
              end

              def options
                config.flat_map { |k,v| option(k,v) }.compact.join(" ")
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

              def failure_message(message)
                sh.echo "Skipping deployment with the #{config[:provider]} provider because #{message}.", ansi: :red
              end

              def negate(conditions)
                conditions = Array(conditions).flatten.compact
                conditions = conditions.map { |condition| " ! #{condition}" }
                conditions.join(' && ') if conditions.any?
              end
          end
        end
      end
    end
  end
end
