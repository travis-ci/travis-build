require 'pathname'

class Examples
  class << self
    def top
      @top ||= Pathname.new(`git rev-parse --show-toplevel`.strip)
    end

    def fake_homedir
      @fake_homedir ||= top.join('tmp/examples-homedir')
    end

    def fake_root
      @fake_root ||= top.join('tmp/examples-root')
    end

    def examples_dir
      @examples_dir ||= top.join('examples')
    end

    def stages_dir
      @stages_dir ||= top.join('tmp/examples-stages')
    end

    def build_logs_dir
      @build_logs_dir ||= top.join('tmp/examples-build-logs')
    end

    def shfmt_exe
      @shfmt_exe ||= ENV.fetch('SHFMT_EXE', 'shfmt')
    end

    def shfmt(path)
      system(shfmt_exe, path.to_s, %i[out err] => '/dev/null')
    end

    def known_containers
      @known_containers ||= []
    end

    def docker_ps_records
      fmt = '{"running_for":{{json .RunningFor}},"id":{{json .ID}}}'
      `docker ps --no-trunc --format='#{fmt}'`.split("\n").map do |line|
        JSON.parse(line)
      end
    end

    def clean_up_containers(running_for: / (hour|hours|day|days) /)
      docker_ps_records.each do |rec|
        next unless rec.fetch('running_for') =~ running_for
        system('docker', 'rm', '-f', rec['id'], %i[out err] => '/dev/null')
      end

      known_containers.each do |cid|
        system('docker', 'rm', '-f', cid, %i[out err] => '/dev/null')
      end
    end

    def docker_run
      cid = `docker run -d #{docker_image} /sbin/init`.strip
      fail 'could not start docker container' unless $?.exitstatus.zero?
      known_containers << cid
      cid
    end

    def docker_image
      return @docker_image unless @docker_image.nil?
      if ENV.key?('TRAVIS_BUILD_EXAMPLES_DOCKER_IMAGE')
        @docker_image = ENV.fetch(
          'TRAVIS_BUILD_EXAMPLES_DOCKER_IMAGE',
        )
        return @docker_image
      end

      @docker_image = default_docker_image
    end

    def default_docker_image
      conn = Faraday.new('https://git.io') do |f|
        f.use FaradayMiddleware::FollowRedirects, limit: 3
        f.adapter Faraday.default_adapter
      end

      JSON.parse(conn.get('/fAwln').body).fetch('default')
    end

    def list_build_examples
      examples_dir.glob('build*.bash.txt')
    end

    def integration?(txt)
      !(txt =~ /^# TRAVIS-BUILD INTEGRATION EXAMPLE MAGIC COMMENT/).nil?
    end
  end
end

describe 'examples', example: true do
  before :all do
    Examples.build_logs_dir.rmtree if Examples.build_logs_dir.exist?
    %i[
      build_logs_dir
      examples_dir
      fake_homedir
      fake_root
      stages_dir
    ].each do |path|
      Examples.send(path).mkpath
    end
  end

  after :all do
    Examples.clean_up_containers
  end

  Examples.list_build_examples.each do |example|
    describe "examples/#{example.basename}" do
      it 'has valid syntax' do
        expect(Examples.shfmt(example.to_s)).to be true
      end

      it 'can be evaluated' do
        stages_dest = Examples.stages_dir.join(
          "#{example.basename('.bash.txt')}.stages.bash"
        )

        stages_dest.write(
          example.read.match(/.*START_FUNCS(.*)END_FUNCS.*/m)[1]
        )

        homedir = Examples.fake_homedir.join("#{example.basename}/home")
        root = Examples.fake_root.join("#{example.basename}/root")
        dot_travis = homedir.join('.travis')

        [homedir, dot_travis, root].each do |p|
          p.rmtree if p.exist?
          p.mkpath
        end

        script = <<~BASH
          export TRAVIS_ROOT=#{root}
          export TRAVIS_HOME=#{homedir}
          export TRAVIS_BUILD_DIR=#{homedir}/build

          #{Examples.top.join('lib/travis/build/bash/travis_whereami.bash').read}
          #{Examples.top.join('lib/travis/build/bash/travis_setup_env.bash').read}
          travis_setup_env

          source #{stages_dest}
          if [[ -f #{homedir}/.travis/job_stages ]]; then
            source #{homedir}/.travis/job_stages
          fi

          touch #{dot_travis}/done
        BASH

        expect(
          system('bash', '-c', script, %i[out err] => '/dev/null')
        ).to be true

        expect(dot_travis.join('done')).to be_exist
      end

      next unless Examples.integration?(example.read)

      describe "full docker container execution", integration: true do
        let(:logdest) { Examples.build_logs_dir.join("#{example.basename}.log") }
        let(:cid) { Examples.docker_run }
        let :script do
          <<~BASH
          echo >/var/tmp/build.log &&
            cp /examples/#{example.basename} ~/build.sh &&
            export TRAVIS_FILTERED=pty &&
            bash ~/build.sh 2>&1 | tee /var/tmp/build.log
          BASH
        end

        before do
          logdest.unlink if logdest.exist?
        end

        it 'is successful' do
          system(
            'docker', 'exec', '--user', 'travis', cid,
            'sudo', 'mkdir', '-p', '/examples',
            %i[out err] => '/dev/null'
          )
          expect($?.exitstatus).to be_zero,
            "expected creation of examples dir in #{cid}, got #{$?.exitstatus}"

          system(
            'docker', 'cp',
            example.to_s, "#{cid}:/examples/#{example.basename}"
          )
          expect($?.exitstatus).to be_zero,
            "expected example copy to container #{cid}, got #{$?.exitstatus}"

          system(
            'docker', 'exec', '--user', 'travis', cid,
            'bash', '-c', script,
            %i[out err] => logdest.to_s
          )

          expect($?.exitstatus).to be_zero,
            "expected script exec in container #{cid}, got #{$?.exitstatus}"

          log_minus_header = logdest.read.sub(
            /.*Network availability confirmed\./m, ''
          )
          expect(log_minus_header).to match(/^Done\. Your build exited with 0\./)
        end
      end
    end
  end
end
