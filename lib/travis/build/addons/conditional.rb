module Travis
  module Build
    class Addons
      class Conditional
        VERSIONED_RUNTIMES = %i(
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
        )

        attr_accessor :sh, :addon, :config

        def initialize(sh, addon, config)
          @sh = sh
          @addon = addon
          @config = config
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
        end

        def warning_messages
          warning_message_unless(repo_condition, "this repo's name does not match one specified in .travis.yml's deploy.on.repo: #{on[:repo]}")
          warning_message_unless(branch_condition, "this branch is not permitted")
          warning_message_unless(runtime_conditions, "this is not on the required runtime")
          warning_message_unless(custom_conditions, "a custom condition was not met")
          warning_message_unless(tags_condition, "this is not a tagged commit")
        end

        private

        def repo_condition
          "$TRAVIS_REPO_SLUG = \"#{on[:repo]}\"" if on[:repo]
        end

        def branch_condition
          return if on[:all_branches] || on[:tags]

          branch_config = on[:branch].respond_to?(:keys) ? on[:branch].keys : on[:branch]

          branches  = Array(branch_config || default_branches)

          branches.map { |b| "$TRAVIS_BRANCH = #{b}" }.join(' || ')
        end

        def runtime_conditions
          (VERSIONED_RUNTIMES & on.keys).map { |runtime| "$TRAVIS_#{runtime.to_s.upcase}_VERSION = #{on[runtime].to_s.shellescape}" }
        end

        def custom_conditions
          on[:condition]
        end

        def tags_condition
          case on[:tags]
          when true  then '"$TRAVIS_TAG" != ""'
          when false then '"$TRAVIS_TAG" = ""'
          end
        end

        def warning_message_unless(condition, message)
          return if negate_condition(condition) == ""

          sh.if(negate_condition(condition)) { warning_message(message) }
        end


        def default_branches
          default_branches = config.except(:edge).values.grep(Hash).map(&:keys).flatten(1).uniq.compact
          default_branches.any? ? default_branches : 'master'
        end

        def warning_message(message)
          sh.echo "Skipping a deployment with the #{config[:provider]} provider because #{message}", ansi: :yellow
        end

        def negate_condition(conditions)
          Array(conditions).flatten.compact.map { |condition| " ! (#{condition})" }.join(" && ")
        end
      end
    end
  end
end