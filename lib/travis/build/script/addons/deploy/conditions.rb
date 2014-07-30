require 'shellwords'

module Travis
  module Build
    class Script
      module Addons
        class Deploy
          class Conditions
            RUNTIMES = [:jdk, :node, :perl, :php, :python, :ruby, :scala, :go]

            CONDITIONS = {
              is_pull_request: 'the current build is a pull request',
              matches_repo:    'this is a forked repo',
              matches_branch:  'this branch is not permitted to deploy as per configuration',
              matches_tag:     'this is not on the required runtime',
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

            def each(options = { negate: false })
              all(options).each do |name, condition|
                yield condition, CONDITIONS[name]
              end
            end

            private

              def all(options = { negate: false })
                pairs = CONDITIONS.keys.map { |name| [name, send(name)] }
                pairs = pairs.reject { |name, condition| condition.nil? }
                pairs = pairs.map { |name, condition| [name, negate(condition)] } if options[:negate]
                pairs = pairs.map { |name, condition| [name, "(#{condition})"]  } if pairs.size > 1
                Hash[*pairs.flatten]
              end

              def is_pull_request
                "-z $TRAVIS_PULL_REQUEST"
              end

              def matches_repo
                "$TRAVIS_REPO_SLUG = #{escape(config.on[:repo])}" if config.on[:repo]
              end

              def matches_branch
                return if config.on[:all_branches]
                branches = Array(config.on[:branch] || default_branches)
                branches.map { |b| "$TRAVIS_BRANCH = #{escape(b)}" }.join(' || ')
              end

              def matches_tag
                case config.on[:tags]
                when true  then '-n $TRAVIS_TAG'
                when false then '-z $TRAVIS_TAG' # TODO ask Konstantin
                end
              end

              def matches_runtime
                runtimes = (RUNTIMES & config.on.keys)
                return if runtimes.empty?
                runtimes.map { |runtime| "$TRAVIS_#{runtime.to_s.upcase}_VERSION = #{escape(config.on[runtime])}" }
              end

              def custom
                return unless config.on[:condition]
                conditions = Array(config.on[:condition])
                conditions = conditions.map { |condition| "(#{condition})" } if conditions.size > 1
                conditions.join(' && ')
              end

              def default_branches
                branches = config.branches
                branches.any? ? branches : 'master'
              end

              def negate(conditions)
                conditions = Array(conditions).flatten.compact
                conditions = conditions.map { |condition| "! #{condition}" }
                conditions.join(' && ')
              end

              def escape(str)
                Shellwords.escape(str)
              end
          end
        end
      end
    end
  end
end
