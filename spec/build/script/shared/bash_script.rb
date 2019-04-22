shared_examples_for 'a bash script' do
  include SpecHelpers::BashScript

  let :bash_script_file do
    if respond_to?(:bash_script_path)
      return bash_script_path
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
    expect(shfmt(bash_script_file.to_s)).to be true
  end

  it 'can be evaluated', example: true do
    stages_dest = stages_dir.join(
      "#{bash_script_file.basename('.bash.txt')}.stages.bash"
    )

    stages_dest.write(
      bash_script_file.read.match(/.*START_FUNCS(.*)END_FUNCS.*/m)[1]
    )

    homedir = fake_homedir.join("#{bash_script_file.basename}/home")
    root = fake_root.join("#{bash_script_file.basename}/root")
    dot_travis = homedir.join('.travis')

    [homedir, dot_travis, root].each do |p|
      p.rmtree if p.exist?
      p.mkpath
    end

    bash_dir = SpecHelpers.top.join('lib/travis/build/bash')

    script = <<~BASH
      export TRAVIS_ROOT=#{root}
      export TRAVIS_HOME=#{homedir}
      export TRAVIS_BUILD_DIR=#{homedir}/build

      #{bash_dir.join('travis_whereami.bash').read}
      #{bash_dir.join('travis_setup_env.bash').read}
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
    let(:logdest) { build_logs_dir.join("#{bash_script_file.basename}.log") }
    let(:cid) { docker_run }
    let :script do
      <<~BASH
        echo >/var/tmp/build.log &&
          cp /examples/#{bash_script_file.basename} ~/build.sh &&
          export TRAVIS_FILTERED=pty &&
          sudo rm -rf /etc/apt/sources.list.d &&
          bash ~/build.sh 2>&1 | tee /var/tmp/build.log
      BASH
    end

    before do
      logdest.unlink if logdest.exist?
    end

    it 'runs and passes' do
      unless integration_example?(bash_script_file.read)
        skip('not an integration example')
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
        bash_script_file.to_s, "#{cid}:/examples/#{bash_script_file.basename}"
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
