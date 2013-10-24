module Travis
  module Build
    class Script
      module Addons
        class Deploy
          VERSIONED_RUNTIMES = [:jdk, :node, :perl, :php, :python, :ruby, :scala, :node]
          USE_RUBY           = '1.9.3'
          attr_accessor :script, :config, :allow_failure

          def initialize(script, config)
            @silent = false
            @script = script
            @config_orig = config.respond_to?(:to_hash) ? config.to_hash : {} unless config.is_a? Array
            @config_orig = config.is_a?(Array) ? config : [config]
          end

          def deploy
            @config_orig.each do |c|
              @config = c
              @allow_failure = config.delete(:allow_failure)
              script.if(want) do
                script.run_stage(:before_deploy)
                run
                script.run_stage(:after_deploy)
              end
            end
          end

          private
            def want
              on          = config.delete(:on) || config.delete(:true) || {}
              on          = { branch: on.to_str } if on.respond_to? :to_str
              on[:ruby] ||= on[:rvm] if on.include? :rvm
              conditions  = [ want_push(on), want_repo(on), want_branch(on), want_runtime(on), want_condition(on), want_tags(on) ]
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
              '$(git describe --tags --exact-match)' if on[:tags]
            end

            def want_condition(on)
              on[:condition]
            end

            def want_runtime(on)
              VERSIONED_RUNTIMES.map do |runtime|
                next unless on.include? runtime
                "$TRAVIS_#{runtime.to_s.upcase}_VERSION = \"#{on[runtime]}\""
              end
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
              script.cmd("rvm #{USE_RUBY} do #{cmd}", *args)
            end

            def options
              config.flat_map { |k,v| option(k,v) }.compact.join(" ")
            end
        end
      end
    end
  end
end
