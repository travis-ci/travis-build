module Travis
  module Build
    class Script
      module Addons
        class Deploy
          VERSIONED_RUNTIMES = [:jdk, :node, :perl, :php, :python, :ruby, :scala, :node]
          attr_accessor :script, :config

          def initialize(script, config)
            @silent = false
            @script = script
            @config = config.respond_to?(:to_hash) ? config.to_hash : {}
          end

          def after_success
            script.if(want) { run_all }
          end

          private
            def want
              on         = config[:on] || {}
              on         = { branch: on.to_str } if on.respond_to? :to_str
              conditions = [ want_push(on), want_repo(on), want_branch(on), want_runtime(on) ]
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
              branches  = Array(on[:branch] || 'master')
              branches.map { |b| "$TRAVIS_BRANCH = #{b}" }.join(' || ')
            end

            def want_runtime(on)
              VERSIONED_RUNTIMES.map do |runtime|
                next unless on.include? runtime
                "$TRAVIS_#{runtime.to_s.upcase}_VERSION = \"#{on[runtime]}\""
              end
            end

            def run_all
              export.each do |key, value|
                script.set(key, value, echo: false, assert: false) if value
              end

              before = Array(config[:before]).compact
              if before.any?
                fold("Preparing deploy to %s") do
                  before.each { |cmd| `#{cmd}` }
                end
              end

              fold("Installing tools for %s deploy") { tools } if respond_to?(:tools, true)
              fold("Deploying to %s") { deploy }

              Array(config[:run]).each do |cmd|
                fold { run(cmd) }
              end
            end

            def export
              {}
            end

            def fold(message = nil)
              @fold_count ||= 0
              @fold_count  += 1
              script.fold("#{fold_name}.#{@fold_count}") do
                say(message % service_name, 33) if message
                yield
              end
            end

            def fold_name
              service_name.split(" ").map(&:downcase).join("_")
            end

            def service_name
              self.class.name[/[^:]+$/].split(/(?=[A-Z])/).join(" ")
            end

            def run(cmd)
              die("Don't know how to execute custom commands on #{service_name}, send help!")
            end

            def die(message)
              say(message, 31)
              # call non-existing function, name recommended by josh
              script.cmd('hslghslhg', assert: true, echo: false)
            end

            def app
              config[:app] || '$(basename $(pwd))'
            end

            def say(message, color = nil)
              return say('\033[%d;1m%s\033[0m' % [color, message]) if color
              script.cmd("echo -e \"#{message}\"", assert: false, echo: false)
            end

            def silent?
              @silent
            end

            def silent
              @silent = true
              yield
            ensure
              @silent = false
            end

            def option(key)
              config.fetch(key) do
                die "#{service_name} addon needs #{key} option"
                "MISSING"
              end
            end

            def `(cmd)
              script.cmd(cmd, assert: true, echo: !silent?)
            end
        end
      end
    end
  end
end
