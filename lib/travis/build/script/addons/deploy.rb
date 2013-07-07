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
            script.if(want) { run }
          end

          private
            def want
              on          = config.delete(:on) || config.delete(:true) || {}
              on          = { branch: on.to_str } if on.respond_to? :to_str
              on[:ruby] ||= on[:rvm] if on.include? :rvm
              conditions  = [ want_push(on), want_repo(on), want_branch(on), want_runtime(on) ]
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

            def want_runtime(on)
              VERSIONED_RUNTIMES.map do |runtime|
                next unless on.include? runtime
                "$TRAVIS_#{runtime.to_s.upcase}_VERSION = \"#{on[runtime]}\""
              end
            end

            def run
              script.fold('dpl.0') { install }
              script.cmd("dpl #{options} --fold || (#{die})", echo: false, assert: false)
            end

            def install(edge = config[:edge])
              return script.cmd("gem install dpl", echo: false, assert: true) unless edge
              script.cmd("git clone https://github.com/rkh/dpl.git")
              script.cmd("cd dpl")
              script.cmd("gem build dpl.gemspec")
              install(false)
              script.cmd("cd ../dpl")
            end

            def die
              'echo "failed to deploy"; travis_terminate 2'
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

            def options
              config.flat_map { |k,v| option(k,v) }.compact.join(" ")
            end
        end
      end
    end
  end
end
