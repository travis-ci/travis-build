require 'spec_helpers/bash_script'

shared_examples_for 'a bash script' do
  include SpecHelpers::BashScript::RSpecContext

  let :example_file do
    if respond_to?(:example_path)
      return example_path
    end

    Pathname.new('nonexistent')
  end

  before :all do
    clean_up_containers
  end

  before do
    %i[
      build_logs_dir
      examples_dir
      fake_homedir
      fake_root
      stages_dir
    ].each do |path|
      send(path).mkpath
    end
  end

  after :all do
    clean_up_containers
  end

  it 'has valid syntax', example: true do
    expect(shfmt(example_file.to_s)).to be true
  end

  it 'can be evaluated', example: true do
    stages_dest = stages_dir.join(
      "#{example_file.basename('.bash.txt')}.stages.bash"
    )

    stages_dest.write(
      example_file.read.match(/.*START_FUNCS(.*)END_FUNCS.*/m)[1]
    )

    homedir = fake_homedir.join("#{example_file.basename}/home")
    root = fake_root.join("#{example_file.basename}/root")
    dot_travis = homedir.join('.travis')

    [homedir, dot_travis, root].each do |p|
      p.rmtree if p.exist?
      p.mkpath
    end

    script = <<~BASH
      export TRAVIS_ROOT=#{root}
      export TRAVIS_HOME=#{homedir}
      export TRAVIS_BUILD_DIR=#{homedir}/build

      #{top.join('lib/travis/build/bash/travis_whereami.bash').read}
      #{top.join('lib/travis/build/bash/travis_setup_env.bash').read}
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

  describe "full docker container execution", example: true, integration: true do
    let(:logdest) { build_logs_dir.join("#{example_file.basename}.log") }
    let(:cid) { docker_run }
    let :script do
      <<~BASH
        echo >/var/tmp/build.log &&
          cp /examples/#{example_file.basename} ~/build.sh &&
          export TRAVIS_FILTERED=pty &&
          bash ~/build.sh 2>&1 | tee /var/tmp/build.log
      BASH
    end

    before do
      logdest.unlink if logdest.exist?
    end

    it 'is successful' do
      unless integration?(example_file.read)
        skip('not available for integration checks')
      end

      system(
        'docker', 'exec', '--user', 'travis', cid,
        'sudo', 'mkdir', '-p', '/examples',
        %i[out err] => '/dev/null'
      )
      expect($?.exitstatus).to be_zero,
        "expected creation of examples dir in #{cid}, got #{$?.exitstatus}"

      system(
        'docker', 'cp',
        example_file.to_s, "#{cid}:/examples/#{example_file.basename}"
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
