require 'ostruct'

describe Travis::Build::Addons::AptPackages, :sexp do
  let(:script)    { stub('script') }
  let(:data)      { payload_for(:push, :ruby, config: { dist: :precise, addons: { apt_packages: config } }, paranoid: paranoid) }
  let(:sh)        { Travis::Shell::Builder.new }
  let(:addon)     { described_class.new(script, sh, Travis::Build::Data.new(data), config) }
  let(:package_safelists) { { precise: ['curl', 'git'] } }
  let(:paranoid)  { true }
  let(:safelist_skip)     { false }
  subject         { sh.to_sexp }

  before :each do
    described_class.instance_variable_set(:@package_safelists, nil)
    described_class.instance_variable_set(:@source_safelists, nil)
    addon.stubs(:skip_safelist?).returns(safelist_skip)
    addon.stubs(:package_safelists).returns(package_safelists)
    script.stubs(:bash).returns('')
    addon.before_prepare
  end

  def apt_get_install_command(*packages)
    "sudo -E apt-get -yq --no-install-suggests --no-install-recommends $(travis_apt_get_options) install #{packages.join(' ')}"
  end

  context 'with multiple safelisted packages' do
    let(:config) { ['git', 'curl'] }

    it { should include_sexp [:cmd, apt_get_install_command('git', 'curl'), echo: true, timing: true] }
  end

  context 'with multiple packages, some safelisted' do
    let(:config) { ['git', 'curl', 'darkcoin'] }

    it { should include_sexp [:cmd, apt_get_install_command('git', 'curl'), echo: true, timing: true] }
  end

  context 'with multiple packages, some safelisted on unrestricted box' do
    let(:config) { ['git', 'curl', 'darkcoin'] }
    let(:paranoid) { false }

    it { should include_sexp [:cmd, apt_get_install_command('git', 'curl', 'darkcoin'), echo: true, timing: true] }
  end

  context 'with singular safelisted package' do
    let(:config) { 'git' }

    it { should include_sexp [:cmd, apt_get_install_command('git'), echo: true, timing: true] }
  end

  context 'with no safelisted packages' do
    let(:config) { nil }

    it { should_not include_sexp [:cmd, apt_get_install_command('git'), echo: true, timing: true] }
  end
end
