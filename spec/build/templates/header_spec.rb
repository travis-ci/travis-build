describe 'header.sh', integration: true do
  let(:top) { Pathname.new(ENV.fetch('TOP')) }
  let(:header_sh) { top.join('./lib/travis/build/templates/header.sh') }
  let(:build_dir) { Dir.mktmpdir(%w(travis-build- -header-spec)) }

  after :each do
    FileUtils.rm_rf(build_dir)
  end

  let :header_rendered do
    Travis::Build::Template::Template.new(
      build_dir: build_dir,
      root: build_dir,
      home: build_dir,
      internal_ruby_regex: Travis::Build.config.internal_ruby_regex.untaint
    ).render(header_sh)
  end

  let :bash_body do
    script = ["source $HOME/.travis/job_stages", "export"]
    header_sh.read.split("\n").grep(/^[a-z][a-z_]+\(\) \{/).each do |func|
      script << "type #{func.match(/^(.+)\(\) \{/)[1]}"
    end
    script.join("\n")
  end

  let :bash_output do
    IO.popen(
      [
        'env', '-i', "HOME=#{build_dir}",
        'bash', '-c', header_rendered + bash_body, err: %i(child out)
      ]
    ).read
  end

  it 'can render' do
    expect(header_rendered).to_not be_empty
  end

  %w(
    travis_assert
    travis_cmd
    travis_fold
    travis_internal_ruby
    travis_jigger
    travis_nanoseconds
    travis_result
    travis_retry
    travis_terminate
    travis_time_finish
    travis_time_start
    travis_wait
  ).each do |api_function|
    it "defines #{api_function}" do
      expect(bash_output).to match(/^#{api_function} is a function/)
    end
  end

  {
    SHELL: /.+/, # nonempty
    TERM: 'xterm',
    USER: 'travis'
  }.each do |env_var, val|
    it "exports #{env_var}" do
      expect(bash_output).to match(/^declare -x #{env_var}="#{val}"$/)
    end
  end

  describe 'internal ruby selection' do
    let(:rubies) { [] }

    let :bash_body do
      <<-EOF.gsub(/^\s+> ?/, '')
        > source $HOME/.travis/job_stages
        > rvm() {
        >   if [[ $1 != list && $2 != strings ]]; then
        >     return
        >   fi
        >   cat <<EORVM
        > #{rubies.join("\n")}
        > EORVM
        > }
        >
        > echo $(travis_internal_ruby)
      EOF
    end

    context 'with a typical selection of preinstalled rubies' do
      let :rubies do
        %w(
          ree-1.8.7-2012.02
          ruby-1.8.7-p374
          ruby-1.9.2-p330
          ruby-1.9.3-p551
          ruby-2.0.0-p648-clang
          ruby-2.1.2
          ruby-2.1.3
          ruby-2.1.4
          ruby-2.1.5
          ruby-2.2.5
          ruby-2.3.1
        )
      end

      it 'selects the latest valid version' do
        expect(bash_output.strip).to match(/^2\.2\.5$/)
      end
    end

    context 'when the most recent valid version of ruby is 1.9.3' do
      let :rubies do
        %w(
          ree-1.8.7-2012.02
          ruby-1.8.7-p374
          ruby-1.9.2-p330
          ruby-1.9.3-p551
          ruby-2.3.0
          ruby-2.3.1
        )
      end

      it 'selects 1.9.3' do
        expect(bash_output.strip).to match(/^1\.9\.3$/)
      end
    end

    context 'when the most recent valid version of ruby has a 2-digit patch level' do
      let :rubies do
        %w(
          ruby-2.1.2
          ruby-2.1.3
          ruby-2.1.4
          ruby-2.1.5
          ruby-2.1.10
          ruby-2.3.0
          ruby-2.3.1
        )
      end

      it 'selects the highest version with a 2-digit patch level' do
        expect(bash_output.strip).to match(/^2\.1\.10$/)
      end
    end
  end
end
