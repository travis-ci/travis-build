require 'spec_helper'

describe Travis::Build::Script::Smalltalk, :sexp do
  let(:data)   { payload_for(:push, :smalltalk) }
  let(:script) { described_class.new(data) }
  subject      { script.sexp }

  it_behaves_like 'compiled script' do
    let(:code) { ['TRAVIS_LANGUAGE=smalltalk'] }
    let(:cmds) { ['$SMALLTALK_CI_HOME/run.sh'] }
  end

  it "downloads and extracts correct script" do
    should include_sexp [:cmd, "wget -q -O smalltalkCI.zip https://github.com/hpi-swa/smalltalkCI/archive/master.zip", assert: true, echo: true, timing: true]
    should include_sexp [:cmd, "unzip -q -o smalltalkCI.zip", assert: true, echo: true, timing: true]
    should include_sexp [:cmd, "pushd smalltalkCI-* > /dev/null", assert: true, timing: true]
    should include_sexp [:cmd, "source env_vars", assert: true, echo: true, timing: true]
    should include_sexp [:cmd, "popd > /dev/null; popd > /dev/null", assert: true, timing: true]
  end

  describe 'on Linux' do
    before do
      data[:config][:os] = 'linux'
    end
    it 'installs the dependencies' do
      should include_sexp [:cmd, "sudo apt-get install --no-install-recommends libc6:i386 libuuid1:i386 libfreetype6:i386", retry: true]
    end
  end

  describe 'on OS X' do
    before do
      data[:config][:os] = 'osx'
    end
    it 'does not try to call apt-get' do
      should_not include_sexp [:cmd, "sudo apt-get install --no-install-recommends libc6:i386 libuuid1:i386 libfreetype6:i386", retry: true]
    end
  end

  describe 'set smalltalk version' do
    before do
      data[:config][:smalltalk] = 'Squeak-5.0'
    end

    it 'sets SMALLTALK to correct version' do
      should include_sexp [:export, ['SMALLTALK', 'Squeak-5.0']]
    end
  end

end
