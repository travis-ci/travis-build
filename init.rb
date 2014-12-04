module Travis
  module CLI
    class Run < RepoCommand
      description "executes a stage from the .travis.yml"
      on '-p', '--print', 'output stage instead of running it'

      def setup
        error "run command is not available on #{RUBY_VERSION}" if RUBY_VERSION < '1.9.3'
        $:.unshift File.expand_path('../lib', __FILE__)
        require 'travis/build'
      end

      def run(*stages)
        stages << 'script' if stages.empty?
        script = Travis::Build.script(data)
        stages.each do |stage|
          script.sh.export('TRAVIS_STAGE', stage, :echo => false)
          script.run_stage(stage.to_sym)
        end
        source = script.header(Dir.pwd) + "\n" + script.sh.to_s
        print? ? puts(source) : run_script(source, *stages)
      end

      private

        def run_script(source, *stages)
          script = File.expand_path(
            "~/.travis/.build/#{find_slug}/travis-build-" << stages.join('-')
          )
          FileUtils.mkdir_p(File.dirname(script))
          File.open(script, 'w') { |f| f.write(source) }
          FileUtils.chmod(0755, script)
          exec(script)
        end

        def data
          {
            :config => travis_config
          }
        end
    end
  end
end
