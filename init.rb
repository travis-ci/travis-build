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
          script.set('TRAVIS_STAGE', stage, :echo => false)
          script.run_stage(stage.to_sym)
        end
        source = File.read(__FILE__).split("\n__END__\n", 2)[1] + script.sh.to_s
        print? ? puts(source) : exec(source)
      end

      private

        def data
          {
            :config => travis_config
          }
        end
    end
  end
end

__END__

travis_result() { return; }

travis_assert() {
  local result=$?
  if [ $result -ne 0 ]; then
    echo -e "\n\033[33;1mThe command \"$TRAVIS_CMD\" failed and exited with $result during $TRAVIS_STAGE.\e[0m\n\nYour build has been stopped."
    travis_terminate 2
  fi
}

travis_terminate() {
  exit $1
}

travis_retry() {
  "$@"
  return $?
}

