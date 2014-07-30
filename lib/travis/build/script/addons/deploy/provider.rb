require 'travis/build/script/addons/deploy/config'

module Travis
  module Build
    class Script
      module Addons
        class Deploy
          class Provider
            VERSIONED_RUNTIMES = [:jdk, :node, :perl, :php, :python, :ruby, :scala, :go]
            USE_RUBY           = '1.9.3'

            attr_accessor :sh, :data, :config, :stages, :allow_failure

            def initialize(sh, data, config)
              @silent = false # TODO what's with silent? did i break something here?
              @sh = sh
              @data = data
              @config = Config.new(data, config)
            end

            def deploy
              sh.if(conditions) do
                sh.cmd stage(:before_deploy)
                run
                sh.cmd stage(:after_deploy)
              end

              sh.else do
                failure_message_unless(pull_request_condition, 'the current build is a pull request')
                failure_message_unless(repo_condition, 'this is a forked repo')
                failure_message_unless(branch_condition, 'this branch is not permitted deploy')
                failure_message_unless(runtime_conditions, 'this is not on the required runtime')
                failure_message_unless(custom_conditions, 'a custom condition was not met')
                failure_message_unless(tags_condition, 'this is not a tagged commit')
              end
            end

            private

              def stage(name)
                Array(config.stages[name]).each do |cmd|
                  sh.cmd cmd, echo: true, assert: true, timing: true
                end
              end

              def failure_message_unless(condition, message)
                condition = negate(condition)
                sh.if(condition) { failure_message(message) } if condition
              end

              def conditions
                conditions = [
                  pull_request_condition,
                  repo_condition,
                  branch_condition,
                  runtime_conditions,
                  custom_conditions,
                  tags_condition,
                ].flatten.compact
                conditions = conditions.map { |c| "(#{c})" } if conditions.size > 1
                conditions.join(' && ')
              end

              def pull_request_condition
                "-z $TRAVIS_PULL_REQUEST"
              end

              def repo_condition
                "$TRAVIS_REPO_SLUG = \"#{config.on[:repo]}\"" if config.on[:repo]
              end

              def branch_condition
                return if config.on[:all_branches]
                branches = Array(config.on[:branch] || default_branches)
                branches.map { |b| "$TRAVIS_BRANCH = #{b}" }.join(' || ')
              end

              def tags_condition
                case config.on[:tags]
                when true  then '-n $TRAVIS_TAG'
                when false then '-z $TRAVIS_TAG'
                end
              end

              def custom_conditions
                config.on[:condition]
              end

              def runtime_conditions
                runtimes = (VERSIONED_RUNTIMES & config.on.keys)
                runtimes.map { |runtime| "$TRAVIS_#{runtime.to_s.upcase}_VERSION = #{config.on[runtime].shellescape}" }
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

              def install(edge = config.edge?)
                command = 'gem install dpl'
                command << " --pre" if edge
                rvm_cmd command, echo: false, assert: config.assert?, timing: true
              end

              def rvm_cmd(cmd, *args)
                sh.cmd("rvm #{USE_RUBY} --fuzzy do ruby -S #{cmd}", *args)
              end

              def default_branches
                branches = config.branches
                branches.any? ? branches : 'master'
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
