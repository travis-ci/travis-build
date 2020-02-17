module SpecHelpers
  module BashScript
    def fake_homedir
      @fake_homedir ||= SpecHelpers.top.join('tmp/examples-homedir')
    end

    def fake_root
      @fake_root ||= SpecHelpers.top.join('tmp/examples-root')
    end

    def examples_dir
      @examples_dir ||= SpecHelpers.top.join('examples')
    end

    def stages_dir
      @stages_dir ||= SpecHelpers.top.join('tmp/examples-stages')
    end

    def build_logs_dir
      @build_logs_dir ||= SpecHelpers.top.join('tmp/examples-build-logs')
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
      ps_args = [
        '--filter=label=travis-build',
        '--no-trunc',
        %{--format='{"running_for":{{json .RunningFor}},"id":{{json .ID}}}'}
      ]
      `docker ps #{ps_args.join(' ')}`.split("\n").map do |line|
        JSON.parse(line)
      end
    end

    def clean_up_containers(running_for: / (minutes|hour|hours|day|days) /)
      docker_ps_records.each do |rec|
        rf = rec.fetch('running_for')
        next unless rf =~ running_for
        rf_parts = rf.split
        next if rf_parts[1] == 'minutes' && Integer(rf_parts.first) < 5

        system(
          'docker', 'rm', '-f', rec['id'],
          %i[out err] => '/dev/null'
        )
      end

      known_containers.each do |cid|
        system('docker', 'rm', '-f', cid, %i[out err] => '/dev/null')
      end
    end

    def docker_run
      cid = `docker run -l travis-build -d #{docker_image} /sbin/init`.strip
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

      JSON.parse(conn.get('/fphGt').body).fetch('default')
    end

    def list_build_examples
      examples_dir.glob('build*.bash.txt')
    end

    def integration_example?(txt)
      !(txt =~ /^# TRAVIS-BUILD INTEGRATION EXAMPLE MAGIC COMMENT/).nil?
    end
  end
end
