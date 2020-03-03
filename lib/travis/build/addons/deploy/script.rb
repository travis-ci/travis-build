require 'travis/build/addons/deploy/conditions'
require 'travis/build/addons/deploy/config'

module Travis
  module Build
    class Addons
      class Deploy < Base
        class Script
          VERSIONED_RUNTIMES = %i(
            d
            dart
            elm
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
          )

          WANT_18 = true # whether or not we want `dpl` < 1.9

          attr_accessor :script, :sh, :data, :config, :allow_failure, :provider, :index, :last_deploy

          def initialize(script, sh, data, config, index, last_deploy=nil)
            @script = script
            @sh = sh
            @data = data
            @config = config
            @silent = false
            @provider = config[:provider].to_s.gsub(/[^a-z0-9]/, '').downcase
            @index = index
            @last_deploy = last_deploy

            @allow_failure = config.delete(:allow_failure)

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

          private
            def check_conditions_and_run
              sh.if(conditions) do
                run
              end

              sh.else do
                warning_message_unless(repo_condition, "this repo's name does not match one specified in .travis.yml's deploy.on.repo: #{on[:repo]}")
                warning_message_unless(branch_condition, "this branch is not permitted: #{data.branch}")
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
                on = config.delete(:if) || config.delete(:on) || config.delete(true) || config.delete(:true) || {}
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
            rescue TypeError => e
              if e.message =~ /no implicit conversion of Symbol into Integer/
                raise Travis::Build::DeployConditionError.new
              end
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
                sh.fold("dpl_#{index}") { install }
                cmd(run_command, echo: false, assert: false, timing: true)
                sh.raw store_event(event('deploy:finished', deploy_data)) if store_events?
                script.stages.run_stage(:custom, :after_deploy)
              end
            end

            def store_events?
              ENV['TRAVIS_AGENT'] && linux?
            end

            def store_event(event)
              %(echo "#{event.gsub('"', '\"')}" > /tmp/travis/events/event.1)
            end

            def deploy_data
              compact(
                job_id: data.job[:id],
                provider: provider,
                strategy: config[:strategy],
                status: '$TRAVIS_TEST_RESULT',
                edge: config[:edge]
              )
            end

            def event(name, payload)
              JSON.dump(event: name, payload: payload, datetime: Time.now)
            end

            def install
              if edge_changed?(last_deploy, config)
                cmd "gem uninstall -aIx dpl", echo: true
              end
              sh.if "-f $HOME/.rvm/scripts/rvm" do
                sh.if "$(rvm use $(travis_internal_ruby) do ruby -e \"puts RUBY_VERSION\") = 1.9*" do
                  cmd(dpl_install_command(WANT_18), echo: true, assert: !allow_failure, timing: true)
                end
                sh.else do
                  cmd(dpl_install_command, echo: true, assert: !allow_failure, timing: true)
                end
              end
              sh.else do
                sh.if "$(ruby -e \"puts RUBY_VERSION\") = 1.9*" do
                  cmd(dpl_install_command(WANT_18), echo: true, assert: !allow_failure, timing: true)
                end
                sh.else do
                  cmd(dpl_install_command, echo: true, assert: !allow_failure, timing: true)
                end
              end
              sh.cmd "rm -f $TRAVIS_BUILD_DIR/dpl-*.gem", echo: false, assert: false, timing: false
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
              when false      then dpl2? ? "--no-#{key}" : nil
              when nil        then nil
              else "--%s=%p" % [key, value]
              end
            end

            def dpl2?
              # this is not 100% accurate, but chances are low that people run
              # into using false values (not supported in v1 anyway) while we
              # release dpl v2 gradually.
              !!config[:edge]
            end

            def cmd(cmd, *args)
              sh.if "-e $HOME/.rvm/scripts/rvm" do
                sh.cmd('type rvm &>/dev/null || source ~/.rvm/scripts/rvm', echo: false, assert: false)
                sh.cmd("rvm $(travis_internal_ruby) --fuzzy do ruby -S #{cmd}", *args)
              end
              sh.else do
                sh.cmd("ruby -S #{cmd}", *args)
              end
            end

            def dpl_install_command(want_pre_19 = false)
              edge = config[:edge]
              if edge.respond_to? :fetch
                src = edge.fetch(:source, 'travis-ci/dpl')
                branch = edge.fetch(:branch, 'master')
                build_gem_locally_from(src, branch)
              end

              command = "gem install"
              if install_local?(edge)
                command << " $TRAVIS_BUILD_DIR/dpl-*.gem"
              else
                command << " dpl"
              end
              command << " -v '< 1.9' " if want_pre_19
              command << " --pre" if edge
              command
            end

            def options
              config.flat_map { |k,v| option(k,v) }.compact.join(" ")
            end

            def warning_message(message)
              sh.echo "Skipping a deployment with the #{provider} provider because #{message}", ansi: :yellow
            end

            def negate_condition(conditions)
              Array(conditions).flatten.compact.map { |condition| " ! (#{condition})" }.join(" && ")
            end

            def build_gem_locally_from(source, branch)
              sh.echo "Building dpl gem locally with source #{source} and branch #{branch}", ansi: :yellow
              cmd("gem uninstall -aIx dpl >& /dev/null",                echo: false, assert: !allow_failure, timing: false)
              sh.cmd("pushd /tmp >& /dev/null",                             echo: false, assert: !allow_failure, timing: true)
              sh.cmd("git clone https://github.com/#{source} #{source}",    echo: true,  assert: !allow_failure, timing: true)
              sh.cmd("pushd #{source} >& /dev/null",                        echo: false, assert: !allow_failure, timing: true)
              sh.cmd("git checkout #{branch}",                              echo: true,  assert: !allow_failure, timing: true)
              sh.cmd("git rev-parse HEAD",                                echo: true,  assert: !allow_failure, timing: true)
              cmd("gem build dpl.gemspec",                                  echo: true,  assert: !allow_failure, timing: true)
              sh.raw "for f in dpl-*.gemspec; do"
              sh.raw "  base=${f%*.gemspec}"
              sh.raw "  if [[ x$(echo #{provider} | tr A-Z a-z | sed 's/[^a-z0-9]//g') = x$(echo ${base#dpl-*} | tr A-Z a-z | sed 's/[^a-z0-9]//g') ]]; then"
              cmd    "    gem build $f;", echo: true, assert: !allow_failure, timing: true
              sh.raw "    break;"
              sh.raw "  fi"
              sh.raw "done"
              sh.cmd("mv dpl-*.gem $TRAVIS_BUILD_DIR >& /dev/null",         echo: false, assert: !allow_failure, timing: false)
              sh.cmd("popd >& /dev/null",                                   echo: false, assert: !allow_failure, timing: false)
              # clean up, so that multiple edge providers can be run
              sh.cmd("rm -rf $(dirname #{source})",                         echo: false, assert: !allow_failure, timing: false)
              sh.cmd("popd >& /dev/null",                                   echo: false, assert: !allow_failure, timing: false)
            ensure
              sh.cmd("test -e /tmp/dpl && rm -rf dpl", echo: false, assert: false, timing: true)
            end

            def install_local?(edge)
              edge == 'local' || edge.respond_to?(:fetch)
            rescue
              false
            end

            def edge_changed?(last_deploy, config)
              (last_deploy && last_deploy[:edge] && config.nil?) ||
              (last_deploy.nil? && config && config[:edge]) ||
              (last_deploy && config && last_deploy[:edge] != config[:edge])
            end

            def linux?
              script.config[:os] == 'linux'
            end

            def owner_name
              data.slug.split('/').first
            end

            def compact(hash)
              hash.reject { |_, value| value.nil? }.to_h
            end
        end
      end
    end
  end
end
