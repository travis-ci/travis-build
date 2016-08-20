require 'shellwords'

module Travis
  module Build
    class Addons
      class Deploy < Base
        class Conditions
          MESSAGES = {
            is_pull_request: 'the current build is a pull request',
            matches_repo:    'this is a forked repo',
            matches_branch:  'this branch is not permitted to deploy as per configuration',
            is_tag:          'this is not on a tagged build',
            is_not_tag:      'this is on a tagged build',
            matches_runtime: 'this is not on the required runtime',
            custom:          'a custom condition was not met'
          }

          attr_reader :config

          def initialize(config)
            @config = config
          end

          def to_s
            all.values.compact.join(' && ')
          end

          def each_with_message(options = { negate: false })
            all(options).each do |name, condition|
              yield condition, MESSAGES[name]
            end
          end

          private

            def all(options = { negate: false })
              methods = %w(is_ matches_ custom).map { |prefix| private_methods(false).grep(/^#{prefix}/) }.flatten
              pairs = methods.map { |name| send(name) }.compact
              pairs = pairs.map { |name, condition| [name, negate(condition)] } if options[:negate]
              pairs = pairs.map { |name, condition| [name, "(#{condition})"]  } if pairs.size > 1
              Hash[*pairs.flatten]
            end

            def is_pull_request
              [:is_pull_request, "-z $TRAVIS_PULL_REQUEST"]
            end

            def matches_repo
              [:matches_repo, "$TRAVIS_REPO_SLUG = #{escape(config.on[:repo])}"] if config.on[:repo]
            end

            def matches_branch
              return if config.on[:all_branches]
              [:matches_branch, config.branches.map { |b| "$TRAVIS_BRANCH = #{escape(b)}" }.join(' || ')]
            end

            def matches_tag
              case config.on[:tags]
              when true  then [:is_tag,     '-n $TRAVIS_TAG']
              when false then [:is_not_tag, '-z $TRAVIS_TAG']
              end
            end

            def matches_runtime
              return if config.runtimes.empty?
              conditions = config.runtimes.map { |runtime| "$TRAVIS_#{runtime.to_s.upcase}_VERSION = #{escape(config.on[runtime])}" }
              [:matches_runtime, conditions.join(' && ')]
            end

            def custom
              return unless config.on[:condition]
              conditions = Array(config.on[:condition])
              conditions = conditions.map { |condition| "(#{condition})" } if conditions.size > 1
              [:custom, conditions.join(' && ')]
            end

            def default_branches
              branches = config.branches
              branches.any? ? branches : 'master'
            end

            def negate(conditions)
              conditions = Array(conditions).flatten.compact
              conditions = conditions.map { |condition| "! (#{condition})" }
              conditions.join(' && ')
            end

            def escape(str)
              Shellwords.escape(str.to_s)
            end
        end
      end
    end
  end
end
