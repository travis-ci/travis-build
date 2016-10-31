require 'travis/build/addons/deploy/conditions'
require 'travis/build/addons/deploy/config'

module Travis
  module Build
    class Addons
      class Deploy < Base
        class Script
          VERSIONED_RUNTIMES = %w(
            d
            dart
            elixir
            ghc
            go
            haxe
            jdk
            julia
            mono
            node
            otp_release
            perl
            php
            python
            r
            ruby
            rust
            scala
            smalltalk
          ).map(&:to_sym)

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

              branch_config = on[:branch].respond_to?(:keys) ? on[:branch].keys : on[:branch]

              branches  = Array(branch_config || default_branches)
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

            def default_branches
              default_branches = config.except(:edge).values.grep(Hash).map(&:keys).flatten(1).uniq.compact
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
              sh.cmd('type rvm &>/dev/null || source ~/.rvm/scripts/rvm', echo: false, assert: false)
              sh.cmd("rvm $(travis_internal_ruby) --fuzzy do ruby -S #{cmd}", *args)
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

            def build_gem_locally_from(source, branch)
              sh.echo "Building dpl gem locally with source #{source} and branch #{branch}", ansi: :yellow
              sh.cmd("gem uninstall -a -x dpl >& /dev/null",                echo: false, assert: !allow_failure, timing: false)
              sh.cmd("pushd /tmp >& /dev/null",                             echo: false, assert: !allow_failure, timing: true)
              sh.cmd("git clone https://github.com/#{source} #{source}",    echo: true,  assert: !allow_failure, timing: true)
              sh.cmd("pushd #{source} >& /dev/null",                        echo: false, assert: !allow_failure, timing: true)
              sh.cmd("git checkout #{branch}",                              echo: true,  assert: !allow_failure, timing: true)
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
