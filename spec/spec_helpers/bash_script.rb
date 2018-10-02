require 'pathname'

module SpecHelpers
  module BashScript
    module RSpecContext
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
end
