require 'spec_helper'

describe Travis::Build::Script::Smalltalk, :sexp do
  APT_GET_BASE = 'sudo apt-get install -y --no-install-recommends libc6:i386 libuuid1:i386 libfreetype6:i386 libssl1.0.0:i386'

  let(:data)      { payload_for(:push, :smalltalk) }
  let(:script)    { described_class.new(data) }
  let(:defaults)  { described_class::DEFAULTS }
  subject         { script.sexp }
  it              { store_example }

  it_behaves_like 'a bash script'

  it_behaves_like 'compiled script' do
    let(:code) { ['TRAVIS_LANGUAGE=smalltalk'] }
    let(:cmds) { ['smalltalkci'] }
  end

  it 'downloads and extracts correct script' do
    should include_sexp [:cmd, 'wget -q -O smalltalkCI.zip https://github.com/hpi-swa/smalltalkCI/archive/master.zip', assert: true, echo: true, timing: true]
    should include_sexp [:cmd, 'unzip -q -o smalltalkCI.zip', assert: true, echo: true, timing: true]
    should include_sexp [:cmd, 'pushd smalltalkCI-* > /dev/null', assert: true, timing: true]
    should include_sexp [:cmd, 'source env_vars', assert: true, echo: true, timing: true]
    should include_sexp [:cmd, 'export PATH="$(pwd)/bin:$PATH"', assert: true, echo: true, timing: true]
    should include_sexp [:cmd, 'popd > /dev/null; popd > /dev/null', assert: true, timing: true]
  end

  describe 'using edge versions' do
    before do
      data[:config][:smalltalk_edge] = {}
      data[:config][:smalltalk_edge][:source] = 'HPI-BP2015H/smalltalkCI'
      data[:config][:smalltalk_edge][:branch] = 'dev'
    end
    it 'installs the correct script' do
      should include_sexp [:cmd, 'wget -q -O smalltalkCI.zip https://github.com/HPI-BP2015H/smalltalkCI/archive/dev.zip', assert: true, echo: true, timing: true]
    end
  end

  describe 'Squeak-5.0 on Linux' do
    before do
      data[:config][:smalltalk] = 'Squeak-5.0'
      data[:config][:os] = 'linux'
    end
    it 'installs default dependencies' do
      should include_sexp [:cmd, APT_GET_BASE, retry: true]
    end
  end

  describe 'Squeak64-5.0 on Linux' do
    before do
      data[:config][:smalltalk] = 'Squeak64-5.0'
      data[:config][:os] = 'linux'
    end
    it 'does not try to call apt-get' do
      should_not include_sexp [:cmd, APT_GET_BASE, retry: true]
    end
  end

  describe 'Squeak-5.0 with Squeak64-5.0 vm on Linux' do
    before do
      data[:config][:smalltalk] = 'Squeak-5.0'
      data[:config][:smalltalk_vm] = 'Squeak64-5.0'
      data[:config][:os] = 'linux'
    end
    it 'does not try to call apt-get' do
      should_not include_sexp [:cmd, APT_GET_BASE, retry: true]
    end
  end

  describe 'Pharo-5.0 on Linux' do
    before do
      data[:config][:smalltalk] = 'Pharo-5.0'
      data[:config][:os] = 'linux'
    end
    it 'installs Pharo dependencies' do
      should include_sexp [:cmd, "#{APT_GET_BASE} libcairo2:i386", retry: true]
    end
  end

  describe 'Pharo64-6.0 on Linux' do
    before do
      data[:config][:smalltalk] = 'Pharo64-6.0'
      data[:config][:os] = 'linux'
    end
    it 'installs Pharo dependencies' do
      should_not include_sexp [:cmd, "#{APT_GET_BASE} libcairo2:i386", retry: true]
    end
  end

  describe 'Squeak on OS X' do
    before do
      data[:config][:smalltalk] = 'Squeak-5.0'
      data[:config][:os] = 'osx'
    end
    it 'does not try to call apt-get' do
      should_not include_sexp [:cmd, APT_GET_BASE, retry: true]
    end
  end

  describe 'GemStone on Linux' do
    before do
      data[:config][:smalltalk] = 'GemStone-3.2.12'
      data[:config][:os] = 'linux'
      defaults[:release_version] = '12.04'
    end

    it 'set hostname' do
      should include_sexp [:cmd, "sed -e \"s/^\\(127\\.0\\.0\\.1.*\\)$/\\1 $(hostname)/\" /etc/hosts | sed -e \"s/^\\(::1.*\\)$/\\1 $(hostname)/\" > /tmp/hosts"]
      should include_sexp [:cmd, 'cat /tmp/hosts | sudo tee /etc/hosts > /dev/null']
    end

    it 'prepare shared memory' do
      should include_sexp [:cmd, 'SMALLTALK_CI_TOTALMEM=$(($(awk \'/MemTotal:/{print($2);}\' /proc/meminfo) * 1024))']
    end

    it 'prepare netldi if necessary' do
      sexp = sexp_find(subject, [:if, '$(grep -sc "^gs64ldi" /etc/services) -eq 0'], [:then])
      expect(sexp).to include_sexp [:cmd, "sudo bash -c 'echo \"gs64ldi         50377/tcp        # Gemstone netldi\"  >> /etc/services'"]
    end

    it 'installs the dependencies' do
      should include_sexp [:cmd, 'sudo apt-get install -y --no-install-recommends ' +
                     'libpam0g:i386 libssl1.0.0:i386 gcc-multilib libstdc++6:i386 ' +
                     'libfreetype6:i386 pstack libgl1-mesa-glx:i386 libxcb-dri2-0:i386', retry: true]
    end
  end

  describe 'GemStone on OS X' do
    before do
      data[:config][:smalltalk] = 'GemStone-3.2.12'
      data[:config][:os] = 'osx'
    end

    it 'set hostname' do
      should include_sexp [:cmd, "sed -e \"s/^\\(127\\.0\\.0\\.1.*\\)$/\\1 $(hostname)/\" /etc/hosts | sed -e \"s/^\\(::1.*\\)$/\\1 $(hostname)/\" > /tmp/hosts"]
      should include_sexp [:cmd, "cat /tmp/hosts | sudo tee /etc/hosts > /dev/null"]
    end

    it 'prepare shared memory' do
      should include_sexp [:cmd, 'SMALLTALK_CI_TOTALMEM=$(($(sysctl hw.memsize | cut -f2 -d\' \') * 1024))']
      should include_sexp [:cmd, "sysctl kern.sysv.shmmax kern.sysv.shmall kern.sysv.shmmin kern.sysv.shmmni | tr \":\" \"=\" | tr -d \" \" >> /tmp/sysctl.conf"]
    end

    it 'prepare netldi if necessary' do
      sexp = sexp_find(subject, [:if, '$(grep -sc "^gs64ldi" /etc/services) -eq 0'], [:then])
      expect(sexp).to include_sexp [:cmd, "sudo bash -c 'echo \"gs64ldi         50377/tcp        # Gemstone netldi\"  >> /etc/services'"]
    end

    it 'does not try to call apt-get' do
      should_not include_sexp [:cmd, 'apt-get', retry: true]
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

  context 'when smalltalk version is given as an array' do
    before do
      data[:config][:smalltalk] = %w(Squeak-5.0)
    end

    it 'sets TRAVIS_SMALLTALK_VERSION to correct version' do
      should include_sexp [:export, ['TRAVIS_SMALLTALK_VERSION', 'Squeak-5.0']]
    end
  end

  describe 'set smalltalk config' do
    before do
      data[:config][:smalltalk_config] = 'mySuperTest.ston'
    end

    it 'sets TRAVIS_SMALLTALK_CONFIG' do
      should include_sexp [:export, ['TRAVIS_SMALLTALK_CONFIG', 'mySuperTest.ston']]
    end
  end

  describe 'set smalltalk vm' do
    before do
      data[:config][:smalltalk_vm] = 'Pharo-vmLatest70'
    end

    it 'sets TRAVIS_SMALLTALK_VM' do
      should include_sexp [:export, ['TRAVIS_SMALLTALK_VM', 'Pharo-vmLatest70']]
    end
  end

end
