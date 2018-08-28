describe Travis::Build::Addons::Homebrew, :sexp do
  let(:script)             { stub('script') }
  let(:data)               { payload_for(:push, :ruby, config: { os: 'osx', addons: { homebrew: brew_config } }, paranoid: paranoid) }
  let(:sh)                 { Travis::Shell::Builder.new }
  let(:addon)              { described_class.new(script, sh, Travis::Build::Data.new(data), brew_config) }
  let(:brew_config)        { {} }
  let(:paranoid)           { true }
  subject                  { sh.to_sexp }

  context 'when on linux' do
    let(:data) { payload_for(:push, :ruby, config: { os: 'linux' }) }

    it 'will not run' do
      expect(addon.before_prepare?).to eql false
    end
  end

  context 'when on osx' do
    let(:data) { payload_for(:push, :ruby, config: { os: 'osx' }) }

    it 'will run' do
      expect(addon.before_prepare?).to eql true
    end
  end

  context 'with packages' do
    before do
      addon.before_prepare
    end

    it { should_not include_sexp [:cmd, 'brew update', echo: true, timing: true] }

    context 'with multiple packages' do
      let(:brew_config) { { packages: ['imagemagick', 'jq'] } }
      let(:brewfile) { <<~BREWFILE }
brew 'imagemagick'
brew 'jq'
      BREWFILE

      it { should include_sexp [:file, ['~/.Brewfile', brewfile]] }
      it { should include_sexp [:cmd, 'brew bundle --global', echo: true, timing: true] }
    end

    context 'with a single package' do
      let(:brew_config) { { packages: 'imagemagick' } }
      let(:brewfile) { <<~BREWFILE }
brew 'imagemagick'
      BREWFILE

      it { should include_sexp [:file, ['~/.Brewfile', brewfile]] }
      it { should include_sexp [:cmd, 'brew bundle --global', echo: true, timing: true] }
    end
  end

  context 'when updating packages first' do
    before do
      addon.before_prepare
    end

    let(:brew_config) { { update: true } }

    it { should include_sexp [:cmd, 'brew update', echo: true, timing: true] }
  end
end
