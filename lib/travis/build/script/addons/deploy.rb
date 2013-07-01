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
              on         = config.delete(:on) || {}
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

            def run
              script.cmd("gem install dpl", echo: false, assert: true)
              script.cmd("dpl #{options} --fold || (#{die})", echo: false, assert: false)
            end

            def die
              'echo "failed to deploy"; travis_terminate 2'
            end

            def options
              config.flat_map { |k,v| Array(v).map { |e| "--%s=%p" % [k,e] } }.join(" ")
            end
        end
      end
    end
  end
end
