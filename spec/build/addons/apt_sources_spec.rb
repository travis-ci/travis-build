describe Travis::Build::Addons::AptSources, :sexp do
  let(:script)    { stub('script') }
  let(:data)      { payload_for(:push, :ruby, config: { addons: { apt_sources: config } }) }
  let(:sh)        { Travis::Shell::Builder.new }
  let(:addon)     { described_class.new(script, sh, Travis::Build::Data.new(data), config) }
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
  let(:whitelist) do
    {
      'deadsnakes-precise' => deadsnakes,
      'packagecloud-precise' => packagecloud
    }
  end
  subject         { sh.to_sexp }

  before do
    addon.stubs(:source_whitelist).returns(whitelist)
    addon.after_prepare
  end

  def apt_add_repository_command(sourceline)
    "sudo -E apt-add-repository -y #{sourceline.inspect}"
  end

  def apt_key_add_command(key_url)
    "curl -sSL #{key_url.inspect} | sudo -E apt-key add -"
  end

  context 'with multiple whitelisted sources' do
    let(:config) { ['deadsnakes-precise'] }

    it { should include_sexp [:cmd, apt_add_repository_command(deadsnakes['sourceline']), echo: true, assert: true, timing: true] }
    it { should_not include_sexp [:cmd, apt_key_add_command(deadsnakes['key_url']), echo: true, assert: true, timing: true] }
  end

  context 'with multiple sources, some whitelisted' do
    let(:config) { ['packagecloud-precise', 'deadsnakes-precise', 'evilbadthings'] }

    it { should include_sexp [:cmd, apt_add_repository_command(packagecloud['sourceline']), echo: true, assert: true, timing: true] }
    it { should include_sexp [:cmd, apt_add_repository_command(deadsnakes['sourceline']), echo: true, assert: true, timing: true] }
    it { should include_sexp [:cmd, apt_key_add_command(packagecloud['key_url']), echo: true, assert: true, timing: true] }
    it { should_not include_sexp [:cmd, apt_key_add_command(deadsnakes['key_url']), echo: true, assert: true, timing: true] }
  end

  context 'with singular whitelisted source' do
    let(:config) { 'packagecloud-precise' }

    it { should include_sexp [:cmd, apt_add_repository_command(packagecloud['sourceline']), echo: true, assert: true, timing: true] }
  end

  context 'with no whitelisted sources' do
    let(:config) { nil }

    it { should_not include_sexp [:cmd, apt_add_repository_command(packagecloud['sourceline']), echo: true, assert: true, timing: true] }
  end
end
