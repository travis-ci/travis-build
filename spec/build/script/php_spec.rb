require 'spec_helper'

describe Travis::Build::Script::Php, :sexp do
  let(:data)     { payload_for(:push, :php) }
  let(:script)   { described_class.new(data) }
  subject(:sexp) { script.sexp }
  it             { store_example }

  it_behaves_like 'a bash script'

  it_behaves_like 'compiled script' do
    let(:code) { ['TRAVIS_LANGUAGE=php'] }
    let(:cmds) { ['phpunit'] }
  end

  it_behaves_like 'a build script sexp'

  it 'sets TRAVIS_PHP_VERSION' do
    should include_sexp [:export, ['TRAVIS_PHP_VERSION', '7.2']]
  end

  it 'sets up the php version' do
    should include_sexp [:cmd, 'phpenv global 7.2 2>/dev/null', echo: true, timing: true]
    should include_sexp [:cmd, 'phpenv rehash']
  end

  it 'announces php --version' do
    should include_sexp [:cmd, 'php --version', echo: true]
  end

  it 'announces composer --version' do
    should include_sexp [:cmd, 'composer --version', echo: true]
  end

  it 'runs phpunit' do
    should include_sexp [:cmd, 'phpunit', echo: true, timing: true]
  end

  context "with minimal config" do
    before do
      data[:config][:language] = 'php'; data[:config].delete(:php)
      described_class.send :remove_const, :DEPRECATIONS
      described_class.const_set("DEPRECATIONS", [
        {
          name: 'PHP',
          current_default: '5.5',
          new_default: '7.3',
          cutoff_date: '2018-03-15',
        }
      ])
    end

    context "before default change cutoff date" do
      before do
        DateTime.stubs(:now).returns(DateTime.parse("2018-01-01"))
      end
      it { should include_sexp [:echo, /Using the default PHP version/, ansi: :yellow] }
    end

    context "after default change cutoff date" do
      before do
        DateTime.stubs(:now).returns(DateTime.parse("2019-01-01"))
      end
      it { should_not include_sexp [:echo, /Using the default PHP version/, ansi: :yellow] }
    end
  end

  describe 'installs php nightly' do
    before { data[:config][:php] = 'nightly' }
    it { should include_sexp [:cmd, 'curl -sSf --retry 5 -o archive.tar.bz2 $archive_url && tar xjf archive.tar.bz2 --directory /', echo: true, timing: true] }
  end

  context 'with php nightly' do
    describe 'writes ~/.pearrc if necessary' do
      before { data[:config][:php] = 'nightly' }
      it { should include_sexp [:echo, 'Writing ${TRAVIS_HOME}/.pearrc', ansi: :yellow] }
    end
  end

  context 'with unrecognized php version' do
    describe 'writes ~/.pearrc if necessary' do
      before { data[:config][:php] = 'foobar' }
      it { should include_sexp [:echo, 'Writing ${TRAVIS_HOME}/.pearrc', ansi: :yellow] }
    end
  end

  context 'with php 5.4' do
    describe 'writes ~/.pearrc if necessary' do
      before { data[:config][:php] = '5.4' }
      it { should include_sexp [:echo, 'Writing ${TRAVIS_HOME}/.pearrc', ansi: :yellow] }
    end
  end

  context 'with php 5.3' do
    before { data[:config][:php] = '5.3' }
    after { store_example(name: '5.3') }
    describe 'does not write ~/.pearrc' do
      it { should_not include_sexp [:echo, 'Writing ${TRAVIS_HOME}/.pearrc', ansi: :yellow] }
    end

    describe 'when running on non-Precise image' do
      let(:sexp) { sexp_find(sexp_filter(subject, [:if, "$(lsb_release -sc 2>/dev/null) != precise"])[0], [:then]) }

      it "terminates early" do
        # These are the last commands of sh.failure
        expect(sexp).to include_sexp [:raw, "set -e", assert: true]
        expect(sexp).to include_sexp [:raw, "false", assert: true]
      end
    end
  end

  describe 'installs php 7' do
    before { data[:config][:php] = '7' }
    it { should include_sexp [:cmd, 'ln -s ~/.phpenv/versions/7.0 ~/.phpenv/versions/7', assert: true, timing: true] }
  end

  context 'when php version is given as array' do
    before { data[:config][:php] = %w(7) }
    it { should include_sexp [:cmd, 'ln -s ~/.phpenv/versions/7.0 ~/.phpenv/versions/7', assert: true, timing: true] }
  end

  describe 'fixes php.ini for hhvm' do
    let(:path)     { '/etc/hhvm/php.ini' }
    let(:addition) { %(date.timezone = "UTC"\nhhvm.libxml.ext_entity_whitelist=file,http,https\n) }
    before { data[:config][:php] = 'hhvm' }
    it { should include_sexp [:raw, "sudo mkdir -p $(dirname #{path}); echo '#{addition}' | sudo tee -a #{path} > /dev/null"] }
    it { should include_sexp [:raw, "sudo chown $(whoami) #{path}"] }
    it { should include_sexp [:raw, "grep session.save_path #{path} | cut -d= -f2 | sudo xargs mkdir -m 01733 -p"] }
  end

   describe 'installs hhvm-nightly' do
    before { data[:config][:php] = 'hhvm-nightly' }
    it { should include_sexp [:cmd, 'travis_apt_get_update'] }
    it { should include_sexp [:cmd, 'sudo apt-get install hhvm-nightly -y 2>&1 >/dev/null'] }
    it { store_example(name: 'hhvm-nightly') }
  end

   describe 'installs specific hhvm version' do
    before { data[:config][:php] = 'hhvm-3.12' }
    it { should include_sexp [:cmd, 'travis_apt_get_update'] }
    it { should include_sexp [:cmd, 'sudo apt-get install -y hhvm', timing: true, assert: true, echo: true] }
    it { should include_sexp [:raw, "echo \"deb [ arch=amd64 ] http://dl.hhvm.com/ubuntu $(lsb_release -sc)-lts-3.12 main\" | sudo tee -a /etc/apt/sources.list >&/dev/null"] }
  end

  describe 'when desired PHP version is not found' do
    let(:version) { '7.0.0beta2' }
    let(:data) { payload_for(:push, :php, config: { php: version }) }
    let(:sexp) { sexp_find(sexp_filter(subject, [:if, "$? -ne 0"])[0], [:then]) }

    it 'installs PHP version on demand' do
      expect(sexp).to include_sexp [:raw, "archive_url=https://s3.amazonaws.com/travis-php-archives/binaries/${travis_host_os}/${travis_rel_version}/$(uname -m)/php-#{version}.tar.bz2", assert: true]
      expect(sexp).to include_sexp [:cmd, "curl -sSf --retry 5 -o archive.tar.bz2 $archive_url && tar xjf archive.tar.bz2 --directory /", echo: true, timing: true]
    end
  end

  # describe 'before_install' do
  #   subject { sexp_filter(sexp, [:if, '-f composer.json'])[0] }

  #   it 'runs composer self-update if composer.json exists' do
  #     should include_sexp [:cmd, 'composer self-update', assert: true, echo: true, timing: true]
  #   end
  # end

  # describe 'install' do
  #   subject { sexp_filter(sexp, [:if, '-f composer.json'])[1] }

  #   describe 'runs composer install if composer.json exists' do
  #     it { should include_sexp [:cmd, 'composer install', assert: true, echo: true, timing: true] }
  #   end

  #   describe 'uses given composer_args' do
  #     before { data[:config].update(composer_args: '--some --args') }
  #     it { should include_sexp [:cmd, 'composer install --some --args', assert: true, echo: true, timing: true] }
  #   end
  # end
end
