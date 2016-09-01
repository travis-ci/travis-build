require 'faraday'
require 'json'

describe Travis::Build::Addons::Apt, :sexp do
  let(:script)            { stub('script') }
  let(:data)              { payload_for(:push, :ruby, config: { addons: { apt: config } }, paranoid: paranoid) }
  let(:sh)                { Travis::Shell::Builder.new }
  let(:addon)             { described_class.new(script, sh, Travis::Build::Data.new(data), config) }
  let(:config)            { {} }
  let(:source_whitelist)  { [{ alias: 'testing', sourceline: 'deb http://example.com/deb repo main' }] }
  let(:package_whitelist) { %w(git curl) }
  let(:paranoid)          { true }
  subject                 { sh.to_sexp }

  before :all do
    Faraday.default_adapter = :test
  end

  before do
    described_class.instance_variable_set(:@package_whitelist, nil)
    described_class.instance_variable_set(:@source_whitelist, nil)
  end

  context 'when on osx' do
    let(:data) { payload_for(:push, :ruby, config: { os: 'osx' }) }

    it 'will not run' do
      expect(addon.before_prepare?).to eql(false)
    end
  end

  context 'when on linux' do
    let(:data) { payload_for(:push, :ruby, config: { os: 'linux' }) }

    it 'will run' do
      expect(addon.before_prepare?).to eql(true)
    end
  end

  context 'when the package whitelist is provided' do
    before do
      described_class.stubs(:fetch_package_whitelist).returns(package_whitelist.join("\n"))
      addon.before_prepare
    end

    it 'exposes a package whitelist' do
      expect(described_class.package_whitelist).to_not be_empty
    end

    it 'instances delegate package whitelist to class' do
      expect(described_class.package_whitelist.object_id).to eql(addon.send(:package_whitelist).object_id)
    end
  end

  context 'when the source whitelist is provided' do
    before do
      described_class.stubs(:fetch_source_whitelist).returns(JSON.dump(source_whitelist))
      addon.before_prepare
    end

    it 'exposes a source whitelist' do
      expect(described_class.source_whitelist).to_not be_empty
    end

    it 'instances delegate source whitelist to class' do
      expect(described_class.source_whitelist.object_id).to eql(addon.send(:source_whitelist).object_id)
    end
  end

  context 'when the package whitelist cannot be fetched' do
    before do
      described_class.stubs(:fetch_package_whitelist).raises(StandardError)
      addon.before_prepare
    end

    it 'defaults package whitelist to empty array' do
      expect(described_class.package_whitelist).to eql([])
    end
  end

  context 'when the source whitelist cannot be fetched' do
    before do
      described_class.stubs(:fetch_source_whitelist).raises(StandardError)
      addon.before_prepare
    end

    it 'defaults source whitelist to empty hash' do
      expect(described_class.source_whitelist).to eql({})
    end
  end

  context 'with packages' do
    before do
      addon.stubs(:package_whitelist).returns(package_whitelist)
      addon.before_prepare
    end

    def apt_get_install_command(*packages)
      "sudo -E apt-get -yq --no-install-suggests --no-install-recommends --force-yes install #{packages.join(' ')}"
    end

    context 'with multiple whitelisted packages' do
      let(:config) { { packages: ['git', 'curl'] } }

      it { store_example("whitelisted")}

      it { should include_sexp [:cmd, apt_get_install_command('git', 'curl'), echo: true, timing: true] }
    end

    context 'with multiple packages, some whitelisted' do
      let(:config) { { packages: ['git', 'curl', 'darkcoin'] } }

      it { should include_sexp [:cmd, apt_get_install_command('git', 'curl'), echo: true, timing: true] }

      context 'when sudo is enabled' do
        let(:paranoid) { false }

        it { should include_sexp [:cmd, apt_get_install_command('git', 'curl', 'darkcoin'), echo: true, timing: true] }
      end

      context 'when TRAVIS_BUILD_APT_WHITELIST_SKIP is set' do
        let(:paranoid) { true }
        before :all do
          ENV['TRAVIS_BUILD_APT_WHITELIST_SKIP'] = '1'
        end

        after :all do
          ENV.delete 'TRAVIS_BUILD_APT_WHITELIST_SKIP'
        end

        it { should include_sexp [:cmd, apt_get_install_command('git', 'curl', 'darkcoin'), echo: true, timing: true] }
      end
    end

    context 'with singular whitelisted package' do
      let(:config) { { packages: 'git' } }

      it { should include_sexp [:cmd, apt_get_install_command('git'), echo: true, timing: true] }
    end

    context 'with no whitelisted packages' do
      let(:config) { { packages: nil } }

      it { should_not include_sexp [:cmd, apt_get_install_command('git'), echo: true, timing: true] }
    end

    context 'with nested arrays of packages' do
      let(:config) { { packages: [%w(git curl)] } }

      it { should include_sexp [:cmd, apt_get_install_command('git', 'curl'), echo: true, timing: true] }
    end
  end

  context 'with sources' do
    let(:deadsnakes) do
      {
        'alias' => 'deadsnakes-precise',
        'sourceline' => 'ppa:fkrull/deadsnakes-precise',
        'key_url' => nil
      }
    end

    let(:packagecloud) do
      {
        'alias' => 'packagecloud-precise',
        'sourceline' => 'deb https://packagecloud.io/chef/stable/ubuntu/ precise main',
        'key_url' => 'https://packagecloud.io/gpg.key'
      }
    end

    let(:evilbadthings) do
      {
        'alias' => 'evilbadthings',
        'sourceline' => 'deb https://evilbadthings.com/chef/stable/ubuntu/ precise main'
      }
    end

    let(:source_whitelist) do
      {
        'deadsnakes-precise' => deadsnakes,
        'packagecloud-precise' => packagecloud
      }
    end

    before do
      addon.stubs(:source_whitelist).returns(source_whitelist)
      addon.before_prepare
    end

    def apt_add_repository_command(sourceline)
      "sudo -E apt-add-repository -y #{sourceline.inspect}"
    end

    def apt_sources_append_command(sourceline)
      "echo #{sourceline.inspect} | sudo tee -a /etc/apt/sources.list > /dev/null"
    end

    def apt_key_add_command(key_url)
      "curl -sSL #{key_url.inspect} | sudo -E apt-key add -"
    end

    context 'with multiple whitelisted sources' do
      let(:config) { { sources: ['deadsnakes-precise'] } }

      it { should include_sexp [:cmd, apt_add_repository_command(deadsnakes['sourceline']), echo: true, assert: true, timing: true] }
      it { should_not include_sexp [:cmd, apt_key_add_command(deadsnakes['key_url']), echo: true, assert: true, timing: true] }
    end

    context 'with multiple sources, some whitelisted' do
      let(:config) { { sources: ['packagecloud-precise', 'deadsnakes-precise', 'evilbadthings', 'ppa:evilbadppa', { sourceline: 'foobar', key_url: 'deadbeef' }] } }

      it { should include_sexp [:cmd, apt_sources_append_command(packagecloud['sourceline']), echo: true, assert: true, timing: true] }
      it { should include_sexp [:cmd, apt_add_repository_command(deadsnakes['sourceline']), echo: true, assert: true, timing: true] }
      it { should include_sexp [:cmd, apt_key_add_command(packagecloud['key_url']), echo: true, assert: true, timing: true] }
      it { should_not include_sexp [:cmd, apt_sources_append_command(evilbadthings['sourceline']), echo: true, assert: true, timing: true] }
      it { should_not include_sexp [:cmd, apt_add_repository_command('ppa:evilbadppa'), echo: true, assert: true, timing: true] }
      it { should_not include_sexp [:cmd, apt_key_add_command(deadsnakes['key_url']), echo: true, assert: true, timing: true] }
      it { should_not include_sexp [:cmd, apt_sources_append_command('foobar'), echo: true, assert: true, timing: true] }
      it { should_not include_sexp [:cmd, apt_key_add_command('deadbeef'), echo: true, assert: true, timing: true] }
    end

    context 'with singular whitelisted source' do
      let(:config) { { sources: 'packagecloud-precise' } }

      it { should include_sexp [:cmd, apt_sources_append_command(packagecloud['sourceline']), echo: true, assert: true, timing: true] }
    end

    context 'with no whitelisted sources' do
      let(:config) { { sources: nil } }

      it { should_not include_sexp [:cmd, apt_add_repository_command(packagecloud['sourceline']), echo: true, assert: true, timing: true] }
    end

    context 'when sudo is enabled' do
      let(:paranoid) { false }
      let(:config) { { sources: ['packagecloud-precise', 'deadsnakes-precise', 'evilbadthings', 'ppa:archivematica/externals', { sourceline: 'foobar', key_url: 'deadbeef' }] } }

      it { should include_sexp [:cmd, apt_sources_append_command(packagecloud['sourceline']), echo: true, assert: true, timing: true] }
      it { should include_sexp [:cmd, apt_add_repository_command(deadsnakes['sourceline']), echo: true, assert: true, timing: true] }
      it { should include_sexp [:cmd, apt_key_add_command(packagecloud['key_url']), echo: true, assert: true, timing: true] }
      it { should include_sexp [:cmd, apt_sources_append_command('foobar'), echo: true, assert: true, timing: true] }
      it { should include_sexp [:cmd, apt_key_add_command('deadbeef'), echo: true, assert: true, timing: true] }
      it { should_not include_sexp [:cmd, apt_sources_append_command(evilbadthings['sourceline']), echo: true, assert: true, timing: true] }
      it { should_not include_sexp [:cmd, apt_add_repository_command('ppa:evilbadppa'), echo: true, assert: true, timing: true] }

      context 'when a malformed source is given' do
        let(:config) { { sources: [{ key_url: 'deadbeef' }] } }
        it { should include_sexp [:echo, "`sourceline` key missing:", ansi: :yellow] }
      end
    end

    context 'when TRAVIS_BUILD_APT_WHITELIST_SKIP env var is set' do
      let(:paranoid) { true }
      let(:config) { { sources: ['packagecloud-precise', 'deadsnakes-precise', 'evilbadthings', 'ppa:archivematica/externals', { sourceline: 'foobar', key_url: 'deadbeef' }] } }

      before :all do
        ENV['TRAVIS_BUILD_APT_WHITELIST_SKIP'] = '1'
      end

      after :all do
        ENV.delete 'TRAVIS_BUILD_APT_WHITELIST_SKIP'
      end

      it { should include_sexp [:cmd, apt_sources_append_command(packagecloud['sourceline']), echo: true, assert: true, timing: true] }
      it { should include_sexp [:cmd, apt_add_repository_command(deadsnakes['sourceline']), echo: true, assert: true, timing: true] }
      it { should include_sexp [:cmd, apt_key_add_command(packagecloud['key_url']), echo: true, assert: true, timing: true] }
      it { should include_sexp [:cmd, apt_sources_append_command('foobar'), echo: true, assert: true, timing: true] }
      it { should include_sexp [:cmd, apt_key_add_command('deadbeef'), echo: true, assert: true, timing: true] }
      it { should_not include_sexp [:cmd, apt_sources_append_command(evilbadthings['sourceline']), echo: true, assert: true, timing: true] }
      it { should_not include_sexp [:cmd, apt_add_repository_command('ppa:evilbadppa'), echo: true, assert: true, timing: true] }

      context 'when a malformed source is given' do
        let(:config) { { sources: [{ key_url: 'deadbeef' }] } }
        it { should include_sexp [:echo, "`sourceline` key missing:", ansi: :yellow] }
      end
    end
  end
end
