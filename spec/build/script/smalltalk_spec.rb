require 'spec_helper'

describe Travis::Build::Script::Smalltalk, :sexp do
  let(:data)      { payload_for(:push, :smalltalk) }
  let(:script)    { described_class.new(data) }
  let(:defaults)  { described_class::DEFAULTS }
  subject         { script.sexp }
  it              { store_example }

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

  describe 'Squeak on Linux' do
    before do
      data[:config][:smalltalk] = 'Squeak-5.0'
      data[:config][:os] = 'linux'
    end
    it 'installs the dependencies' do
      should include_sexp [:cmd, "sudo apt-get install --no-install-recommends libc6:i386 libuuid1:i386 libfreetype6:i386 libssl1.0.0:i386", retry: true]
    end
  end

  describe 'Squeak on OS X' do
    before do
      data[:config][:smalltalk] = 'Squeak-5.0'
      data[:config][:os] = 'osx'
    end
    it 'does not try to call apt-get' do
      should_not include_sexp [:cmd, "sudo apt-get install --no-install-recommends libc6:i386 libuuid1:i386 libfreetype6:i386 libssl1.0.0:i386", retry: true]
    end
  end

  describe 'GemStone on Linux' do
    before do
      data[:config][:smalltalk] = 'GemStone-3.2.12'
      data[:config][:os] = 'linux'
      defaults[:release_version] = '12.04'
    end

    it 'set hostname' do
      should include_sexp [:cmd, "sudo hostname " + defaults[:gemstone_hostname]]
      should include_sexp [:cmd, "cat /tmp/hosts | sudo tee /etc/hosts > /dev/null"]
    end

    it 'installs the dependencies' do
      should include_sexp [:cmd, "sudo apt-get install --no-install-recommends " +
                     "curl git zip unzip libpam0g:i386 libssl1.0.0:i386 " +
                     "gcc-multilib libstdc++6:i386 gdb libfreetype6:i386 " +
                     "pstack libgl1-mesa-glx:i386 libxcb-dri2-0:i386", retry: true]
    end
  end

  describe 'GemStone on OS X' do
    before do
      data[:config][:smalltalk] = 'GemStone-3.2.12'
      data[:config][:os] = 'osx'
    end

    it 'set hostname' do
      should include_sexp [:cmd, "sudo scutil --set HostName " + defaults[:gemstone_hostname]]
      should include_sexp [:cmd, "cat /tmp/hosts | sudo tee /etc/hosts > /dev/null"]
    end

    it 'does not try to call apt-get' do
      should_not include_sexp [:cmd, "sudo apt-get install --no-install-recommends " +
                     "curl git zip unzip libpam0g:i386 libssl1.0.0:i386 " +
                     "gcc-multilib libstdc++6:i386 gdb libfreetype6:i386 " +
                     "pstack libgl1-mesa-glx:i386 libxcb-dri2-0:i386", retry: true]
    end
  end

  describe 'set smalltalk version' do
    before do
      data[:config][:smalltalk] = 'Squeak-5.0'
    end

    it 'sets TRAVIS_SMALLTALK_VERSION to correct version' do
      should include_sexp [:export, ['TRAVIS_SMALLTALK_VERSION', 'Squeak-5.0']]
    end
  end

end
