require 'faraday'
require 'json'

describe Travis::Build::Addons::Apt, :sexp do
  let(:script)             { stub('script') }
  let(:data)               { payload_for(:push, :ruby, config: { dist: dist, addons: { apt: apt_config } }, paranoid: paranoid) }
  let(:sh)                 { Travis::Shell::Builder.new }
  let(:addon)              { described_class.new(script, sh, Travis::Build::Data.new(data), apt_config) }
  let(:apt_config)         { {} }
  let(:dist)               { :xenial }
  let(:source_alias_lists)  { { xenial: [{ alias: 'testing', sourceline: 'deb http://example.com/deb repo main' }] } }
  let(:package_safelists) { { xenial: %w(git curl) } }
  let(:paranoid)           { true }
  let(:safelist_skip)     { false }
  let(:apt_load_source_alias_list) { true }
  subject                  { sh.to_sexp }

  before :all do
    Faraday.default_adapter = :test
  end

  before :each do
    described_class.instance_variable_set(:@package_safelists, nil)
    described_class.instance_variable_set(:@source_alias_lists, nil)
    script.stubs(:bash).returns('')
    addon.stubs(:skip_safelist?).returns(safelist_skip)
    addon.stubs(:load_alias_list?).returns(apt_load_source_alias_list)
  end

  context 'when on osx' do
    let(:data) { payload_for(:push, :ruby, config: { os: 'osx' }) }

    it 'will not run' do
      expect(addon.before_prepare?).to eql(false)
    end
  end

  %w[
    linux
    linux-ppc64le
  ].each do |os|
    context "when on #{os}" do
      let(:data) { payload_for(:push, :ruby, config: { os: os, dist: 'xenial' }) }

      it 'will run' do
        expect(addon.before_prepare?).to eql(true)
      end

      context 'with unknown dist' do
        let(:data) { payload_for(:push, :ruby, config: { os: os, dist: 'dapper' }) }

        it 'will not run' do
          expect(addon.before_prepare?).to eql(false)
        end
      end
    end
  end

  context 'when the package safelist is provided' do
    before do
      described_class.stubs(:fetch_package_safelist)
        .returns(package_safelists[dist].join("\n"))
      addon.before_prepare
    end

    it 'exposes a package safelist' do
      expect(described_class.package_safelists).to_not be_empty
    end

    it 'instances delegate package safelist to class' do
      expect(described_class.package_safelists)
        .to eql(addon.send(:package_safelists))
    end
  end

  context 'when the source safelist is provided' do
    before do
      described_class.stubs(:fetch_source_alias_list)
        .returns(JSON.dump(source_alias_lists[dist]))
      addon.before_prepare
    end

    it 'exposes a source safelist' do
      expect(described_class.source_alias_lists).to_not be_empty
    end

    it 'instances delegate source safelist to class' do
      expect(described_class.source_alias_lists)
        .to eql(addon.send(:source_alias_lists))
    end
  end

  context 'when the package safelist cannot be fetched' do
    before do
      described_class.stubs(:fetch_package_safelist).raises(StandardError)
      addon.before_prepare
    end

    it 'defaults package safelist to empty array' do
      expect(described_class.package_safelists[dist]).to eql([])
    end
  end

  context 'when the source safelist cannot be fetched' do
    before do
      described_class.stubs(:fetch_source_alias_list).raises(StandardError)
      addon.before_prepare
    end

    it 'defaults source safelist to empty hash' do
      expect(described_class.source_alias_lists)
        .to eql({ unset: {}, precise: {}, trusty: {}, xenial: {}, bionic: {} })
    end
  end

  context 'with packages' do
    before do
      addon.stubs(:package_safelists).returns(package_safelists)
      addon.before_prepare
    end

    def apt_get_install_command(*packages)
      "sudo -E apt-get -yq --no-install-suggests --no-install-recommends $(travis_apt_get_options) install #{packages.join(' ')}"
    end

    context 'with multiple safelisted packages' do
      let(:apt_config) { { packages: ['git', 'curl'] } }

      it { store_example(name: 'safelisted') }

      it { should include_sexp [:cmd, apt_get_install_command('git', 'curl'), echo: true, timing: true] }
    end

    context 'with multiple packages, some safelisted' do
      let(:apt_config) { { packages: ['git', 'curl', 'darkcoin'] } }

      it { should include_sexp [:cmd, apt_get_install_command('git', 'curl'), echo: true, timing: true] }

      context 'when sudo is enabled' do
        let(:paranoid) { false }

        it { should include_sexp [:cmd, apt_get_install_command('git', 'curl', 'darkcoin'), echo: true, timing: true] }
      end

      context 'when safelist skippping is enabled' do
        let(:paranoid) { true }
        let(:safelist_skip) { true }

        it { should include_sexp [:cmd, apt_get_install_command('git', 'curl', 'darkcoin'), echo: true, timing: true] }
      end
    end

    context 'with singular safelisted package' do
      let(:apt_config) { { packages: 'git' } }

      it { should include_sexp [:cmd, apt_get_install_command('git'), echo: true, timing: true] }
    end

    context 'with no safelisted packages' do
      let(:apt_config) { { packages: nil } }

      it { should_not include_sexp [:cmd, apt_get_install_command('git'), echo: true, timing: true] }
    end

    context 'with nested arrays of packages' do
      let(:apt_config) { { packages: [%w(git curl)] } }

      it { should include_sexp [:cmd, apt_get_install_command('git', 'curl'), echo: true, timing: true] }
    end
  end

  context 'with sources' do
    let(:deadsnakes) do
      {
        'alias' => 'deadsnakes-xenial',
        'sourceline' => 'ppa:fkrull/deadsnakes-xenial'
      }
    end

    let(:packagecloud) do
      {
        'alias' => 'packagecloud-xenial',
        'sourceline' => 'deb https://packagecloud.io/chef/stable/ubuntu/ xenial main'
      }
    end

    let(:evilbadthings) do
      {
        'alias' => 'evilbadthings',
        'sourceline' => 'deb https://evilbadthings.com/chef/stable/ubuntu/ xenial main'
      }
    end

    let(:source_alias_lists) do
      {
        xenial: {
          'deadsnakes-xenial' => deadsnakes,
          'packagecloud-xenial' => packagecloud
        }
      }
    end

    before do
      addon.stubs(:source_alias_lists).returns(source_alias_lists)
      addon.before_prepare
    end

    def apt_add_repository_command(sourceline)
      "sudo -E apt-add-repository -y #{sourceline.inspect}"
    end

    def apt_sources_append_command(sourceline)
      "echo #{sourceline.inspect} | sudo tee -a ${TRAVIS_ROOT}/etc/apt/sources.list >/dev/null"
    end

    context 'with multiple safelisted sources' do
      let(:apt_config) { { sources: ['deadsnakes-xenial'] } }

      it { should include_sexp [:cmd, apt_add_repository_command(deadsnakes['sourceline']), echo: true, assert: true, timing: true] }
      it { should include_sexp [:cmd, 'travis_apt_get_update', retry: true, echo: true, timing: true] }
    end

    context 'with multiple sources, some safelisted' do
      let(:apt_config) { { sources: ['packagecloud-xenial', 'deadsnakes-xenial', 'evilbadthings', 'ppa:evilbadppa', { sourceline: 'foobar' }] } }

      it { should include_sexp [:cmd, apt_sources_append_command(packagecloud['sourceline']), echo: true, assert: true, timing: true] }
      it { should include_sexp [:cmd, apt_add_repository_command(deadsnakes['sourceline']), echo: true, assert: true, timing: true] }
      it { should_not include_sexp [:cmd, apt_sources_append_command(evilbadthings['sourceline']), echo: true, assert: true, timing: true] }
      it { should_not include_sexp [:cmd, apt_add_repository_command('ppa:evilbadppa'), echo: true, assert: true, timing: true] }
      it { should_not include_sexp [:cmd, apt_sources_append_command('foobar'), echo: true, assert: true, timing: true] }
    end

    context 'with singular safelisted source' do
      let(:apt_config) { { sources: 'packagecloud-xenial' } }

      it { should include_sexp [:cmd, apt_sources_append_command(packagecloud['sourceline']), echo: true, assert: true, timing: true] }
    end

    context 'with no safelisted sources' do
      let(:apt_config) { { sources: nil } }

      it { should_not include_sexp [:cmd, apt_add_repository_command(packagecloud['sourceline']), echo: true, assert: true, timing: true] }
    end

    context 'when sudo is enabled' do
      let(:paranoid) { false }
      let(:apt_config) { { sources: ['packagecloud-xenial', 'deadsnakes-xenial', 'evilbadthings', 'ppa:archivematica/externals', { sourceline: 'foobar' }] } }

      it { should include_sexp [:cmd, apt_sources_append_command(packagecloud['sourceline']), echo: true, assert: true, timing: true] }
      it { should include_sexp [:cmd, apt_add_repository_command(deadsnakes['sourceline']), echo: true, assert: true, timing: true] }
      it { should include_sexp [:cmd, apt_sources_append_command('foobar'), echo: true, assert: true, timing: true] }
      it { should_not include_sexp [:cmd, apt_sources_append_command(evilbadthings['sourceline']), echo: true, assert: true, timing: true] }
      it { should_not include_sexp [:cmd, apt_add_repository_command('ppa:evilbadppa'), echo: true, assert: true, timing: true] }
    end

    context 'when safelist skipping is enabled' do
      let(:paranoid) { true }
      let(:apt_config) { { sources: ['packagecloud-xenial', 'deadsnakes-xenial', 'evilbadthings', 'ppa:archivematica/externals', { sourceline: 'foobar' }] } }
      let(:safelist_skip) { true }

      it { should include_sexp [:cmd, apt_sources_append_command(packagecloud['sourceline']), echo: true, assert: true, timing: true] }
      it { should include_sexp [:cmd, apt_add_repository_command(deadsnakes['sourceline']), echo: true, assert: true, timing: true] }
      it { should include_sexp [:cmd, apt_sources_append_command('foobar'), echo: true, assert: true, timing: true] }
      it { should_not include_sexp [:cmd, apt_sources_append_command(evilbadthings['sourceline']), echo: true, assert: true, timing: true] }
      it { should_not include_sexp [:cmd, apt_add_repository_command('ppa:evilbadppa'), echo: true, assert: true, timing: true] }
    end

    context 'when apt source aliases are not loaded' do
      let(:apt_load_source_alias_list) { false }
      let(:apt_config) { { sources: ['packagecloud-xenial', 'deadsnakes-xenial', 'evilbadthings', 'ppa:archivematica/externals', { sourceline: 'foobar' }] } }

      it { should include_sexp [:echo, "Skipping loading APT source aliases list", ansi: :yellow] }
      it { should_not include_sexp [:echo, /^Disallowing sources: foobar/, ansi: :red] }
      it { should_not include_sexp [:echo, /^Disallowing sources: evilbadthings/, ansi: :red] }
      it { should include_sexp [:cmd, apt_sources_append_command('foobar'), echo: true, assert: true, timing: true] }
      it { should_not include_sexp [:cmd, apt_sources_append_command(packagecloud['sourceline']), echo: true, assert: true, timing: true] }
      it { should_not include_sexp [:cmd, apt_add_repository_command(deadsnakes['sourceline']), echo: true, assert: true, timing: true] }

      context 'with config gives `sources` as a hash' do
        let(:apt_config) { { sources: {
                "sourceline": "deb https://packagecloud.io/chef/stable/ubuntu/ xenial main"
              } } }

        it { should include_sexp [:cmd, apt_sources_append_command(apt_config[:sources][:sourceline]), echo: true, assert: true, timing: true] }
      end
    end
  end

  context "when config.retries is set" do
    let(:apt_config) { { config: { retries: true } } }
    before { addon.before_configure }

    it { store_example(name: 'retries') }

    it { should include_sexp [:echo, "Configuring default apt-get retries", ansi: :yellow] }
  end
end
