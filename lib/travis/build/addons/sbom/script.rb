module Travis
  module Build
    class Addons
      class Sbom < Base
        class Script
          attr_accessor :script, :sh, :data, :config

          def initialize(script, sh, data, config)
            @script = script
            @sh = sh
            @data = data
            @config = config
          end

          def generate
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
                warning_message_unless(branch_condition, "this branch is not permitted: #{data.branch}")
                warning_message_unless(pr_condition, "generation on PR builds is not permitted")
                warning_message_unless(custom_conditions, "a custom condition was not met")
              end
            end

            def warning_message_unless(condition, message)
              return if negate_condition(condition) == ""

              sh.if(negate_condition(condition)) { warning_message(message) }
            end

            def warning_message(message)
              sh.echo "Skipping a SBOM generation because #{message}", ansi: :yellow
            end

            def on
              @on ||= begin
                on = config.delete(:if) || config.delete(:on) || config.delete(true) || config.delete(:true) || {}
                on = { branch: on.to_str } if on.respond_to? :to_str
                on
              end
            end

            def conditions
              [
                branch_condition,
                pr_condition,
                custom_conditions,
              ].flatten.compact.map { |c| "(#{c})" }.join(" && ")
            rescue TypeError => e
              if e.message =~ /no implicit conversion of Symbol into Integer/
                raise Travis::Build::DeployConditionError.new
              end
            end

            def branch_condition
              return if on[:all_branches]

              branch_config = on[:branch][:only].respond_to?(:keys) ? on[:branch][:only].keys : on[:branch][:only]

              branches  = Array(branch_config || default_branches)
              branches.map { |b| "$TRAVIS_BRANCH = #{b}" }.join(' || ')
            end

            def custom_conditions
              on[:condition]
            end

            def pr_condition
              (data.pull_request && on[:pr]) || !data.pull_request ? 'true' : 'false'
            end

            def run
              sh.with_errexit_off do
                sh.fold "sbom" do
                  sh.echo "Starting SBOM generation", ansi: :yellow
                  sh.cmd "mkdir -p #{output_dir}"
                  sh.cmd "docker run --mount type=bind,source=$TRAVIS_BUILD_DIR,target=/app --mount type=bind,source=#{output_dir},target=/structured_sbom_outputs #{Travis::Build.config.sbom.image_url} #{output_format} /structured_sbom_outputs #{input_dirs}".output_safe
                end
              end
            end

            def default_branches
              default_branches = config.except(:edge).values.grep(Hash).map(&:keys).flatten(1).uniq.compact
              default_branches.any? ? default_branches : ['master', 'main']
            end

            def negate_condition(conditions)
              Array(conditions).flatten.compact.map { |condition| " ! (#{condition})" }.join(" && ")
            end

            def input_dirs
              config.key?(:input_dir) ? config[:input_dir].join(',') : '/'
            end

            def output_dir
              config.key?(:output_dir) ? "$TRAVIS_BUILD_DIR/#{config[:output_dir]}" : "$TRAVIS_BUILD_DIR/sbom-#{data.job[:id]}"
            end

            def output_format
              config[:output_format]
            end

            def compact(hash)
              hash.reject { |_, value| value.nil? }.to_h
            end
        end
      end
    end
  end
end
