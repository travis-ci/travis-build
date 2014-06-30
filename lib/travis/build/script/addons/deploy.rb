module Travis
  module Build
    class Script
      module Addons
        class Deploy
          SUPER_USER_SAFE = true

          VERSIONED_RUNTIMES = [:jdk, :node, :perl, :php, :python, :ruby, :scala, :go]
          USE_RUBY           = '1.9.3'
          attr_accessor :script, :config, :allow_failure

          def initialize(script, config)
            @silent = false
            @script = script
            if config.is_a?(Array)
              @configs = config
              @config = {}
            else
              @configs = [config]
              @config = config
            end
          end

          def deploy
            if @configs.length > 1
              @configs.each do |config|
                Deploy.new(script, config).deploy
              end
            else
              @allow_failure = config.delete(:allow_failure)

              script.if(want) do
                script.run_stage(:before_deploy)
                run
                script.run_stage(:after_deploy)
              end

              script.if(negate_condition(want_push(on))) { failure_message "the current build is a pull request." }

              script.if(negate_condition(want_repo(on))) { failure_message "this is a forked repo." } unless want_repo(on).nil?

              script.if(negate_condition(want_branch(on))) { failure_message "this branch is not permitted to deploy." } unless want_branch(on).nil?

              script.if(negate_condition(want_runtime(on))) { failure_message "this is not on the required runtime." } unless want_runtime(on).nil?

              script.if(negate_condition(want_condition(on))) { failure_message "a custom condition was not met." } unless want_condition(on).nil?

              script.if(negate_condition(want_tags(on))) { failure_message "this is not a tagged commit." } unless want_tags(on).nil?
            end
          end

          private
            def on
              @on ||= begin
                on = config.delete(:on) || config.delete(true) || config.delete(:true) || {}
                on = { branch: on.to_str } if on.respond_to? :to_str
                on[:ruby] ||= on[:rvm] if on.include? :rvm
                on[:node] ||= on[:node_js] if on.include? :node_js
                on
              end
            end

            def want
              conditions = [ want_push(on), want_repo(on), want_branch(on), want_runtime(on), want_condition(on), want_tags(on) ]
              conditions.flatten.compact.map { |c| "(#{c})" }.join(" && ")
            end

            def want_push(on)
              '$TRAVIS_PULL_REQUEST = false'
            end

            def want_repo(on)
              "$TRAVIS_REPO_SLUG = \"#{on[:repo]}\"" if on[:repo]
            end

            def want_branch(on)
              return if on[:all_branches]
              branches  = Array(on[:branch] || default_branches)
              branches.map { |b| "$TRAVIS_BRANCH = #{b}" }.join(' || ')
            end

            def want_tags(on)
              case on[:tags]
              when true  then '"$TRAVIS_TAG" != ""'
              when false then '"$TRAVIS_TAG" = ""'
              end
            end

            def want_condition(on)
              on[:condition]
            end

            def want_runtime(on)
              runtimes = VERSIONED_RUNTIMES.map do |runtime|
                           next unless on.include? runtime
                           "$TRAVIS_#{runtime.to_s.upcase}_VERSION = \"#{on[runtime]}\""
                         end.compact.join(" && ")

              runtimes.empty? ? nil : runtimes 
            end

            def run
              script.fold('dpl.0') { install }
              cmd(run_command, echo: false, assert: false)
            end

            def install(edge = config[:edge])
              command = "gem install dpl"
              command << " --pre" if edge
              cmd(command, echo: false, assert: !allow_failure)
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
              when Hash       then option(key, value[script.data.branch.to_sym])
              when true       then "--#{key}"
              when nil, false then nil
              else "--%s=%p" % [key, value]
              end
            end

            def cmd(cmd, *args)
              script.cmd("rvm #{USE_RUBY} --fuzzy do ruby -S #{cmd}", *args)
            end

            def options
              config.flat_map { |k,v| option(k,v) }.compact.join(" ")
            end

            def failure_message(message)
              script.cmd("echo -e \"\033[33;1mSkipping deployment with the " << config[:provider] << " provider because "<< message << "\033[0m\"", echo: false, assert: false, fold: 'deployment')
            end

            def negate_condition(condition)
                " ! " << condition.to_s
            end
        end
      end
    end
  end
end
