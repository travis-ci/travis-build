require 'shellwords'

module SpecHelpers
  module BashFunction
    def run_script(function_name, command, image: 'bash:4', out: nil,
                   err: nil, cleanup: true)
      container_name = "travis_bash_function_#{rand(1000..1999)}"

      out ||= Tempfile.new('travis_bash_function')
      err ||= Tempfile.new('travis_bash_function')

      script = "source /tmp/tbb/#{function_name}.bash; #{command}"

      system(
        %W[
          docker create
            #{cleanup ? '--rm' : ''}
            -e TRAVIS_ROOT=/
            -e TRAVIS_HOME=/home/travis
            -e TRAVIS_BUILD_DIR=/home/travis/build/#{function_name}_spec
            --name=#{container_name}
            #{image}
            bash -c
        ].join(' ') + ' ' + Shellwords.escape(script),
        %i[out err] => '/dev/null'
      )

      system(
        "docker cp #{bash_dir} #{container_name}:/tmp/tbb",
        %i[out err] => '/dev/null'
      )

      truth = system(
        "docker start -i -a #{container_name}",
        out: out.fileno, err: err.fileno
      )

      [out, err].each do |stream|
        stream.rewind if stream.respond_to?(:rewind)
      end

      {
        exitstatus: $?.exitstatus,
        truth: truth,
        out: out,
        err: err
      }
    end

    private def bash_dir
      @bash_dir ||= SpecHelpers.top.join('lib/travis/build/bash')
    end
  end
end
