describe 'script header', integration: true do
  let(:top) { Pathname.new(ENV.fetch('TOP')) }
  let(:build_dir) { Dir.mktmpdir(%w(travis-build- -header-spec)) }
  let(:data) { { config: { language: 'ruby' }, slug: 'example/test' } }
  let(:script) { Travis::Build::Script.new(data) }

  let(:pre_header) do
    <<~PRE_HEADER
      #!/bin/bash
      sudo() { :; }
      lsb_release() { echo xenial; }
    PRE_HEADER
  end

  let :rendered do
    Travis::Shell.generate(script.send(:sh).to_sexp, false)
  end

  let :bash_body do
    script = <<~SCRIPT.split("\n")
      declare -rx "${_RO[@]}"
      unset _RO
      printenv
      export
    SCRIPT
    Travis::Build::Script::TRAVIS_FUNCTIONS.each do |func|
      script << "type #{func}"
    end
    "\n" + script.join("\n")
  end

  let :bash_output do
    IO.popen(
      ['env', '-i', 'bash', '-c', rendered + bash_body, err: %i(child out)]
    ).read
  end

  before do
    script.send(:sh).raw(pre_header)
    script.instance_variable_set(:@root, build_dir)
    script.instance_variable_set(:@home_dir, build_dir)
    script.instance_variable_set(:@build_dir, build_dir)
    script.send(:header)
  end

  after :each do
    FileUtils.rm_rf(build_dir)
  end

  it 'can render' do
    expect(rendered).to_not be_empty
  end

  Travis::Build::Script::TRAVIS_FUNCTIONS.each do |api_function|
    it "defines #{api_function}" do
      expect(bash_output).to match(/^#{api_function} is a function/)
    end
  end

  {
    SHELL: '.+', # nonempty
    TERM: 'xterm',
    USER: 'travis',
    TRAVIS_OS_NAME: 'linux|osx',
    TRAVIS_DIST: 'precise|trusty|xenial'
  }.each do |env_var, val|
    it "exports #{env_var}" do
      expect(bash_output).to match(/^declare -r?x #{env_var}="#{val}"$/)
    end
  end

  describe 'internal ruby selection' do
    let(:rubies) { [] }

    let :bash_body do
      <<~BASH

        rvm() {
          if [[ $1 != list && $2 != strings ]]; then
            return
          fi
          cat <<EORVM
        #{rubies.join("\n")}
        EORVM
        }

        travis_internal_ruby
      BASH
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
