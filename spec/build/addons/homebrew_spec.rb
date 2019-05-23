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
      expect(addon.before_before_install?).to eql false
    end
  end

  context 'when on osx' do
    let(:data) { payload_for(:push, :ruby, config: { os: 'osx' }) }

    it 'will run' do
      expect(addon.before_before_install?).to eql true
    end
  end

  context 'with packages' do
    before do
      addon.before_before_install
    end

    it { should_not include_sexp [:cmd, 'rvm $brew_ruby do brew update', echo: true, timing: true] }

    context 'with multiple packages' do
      let(:brew_config) { { packages: ['imagemagick', 'jq'] } }
      let(:brewfile) { <<~BREWFILE }
brew 'imagemagick'
brew 'jq'
      BREWFILE

      it { should include_sexp [:file, ['~/.Brewfile', brewfile]] }
      it { should include_sexp [:cmd, 'rvm $brew_ruby do brew bundle --verbose --global', echo: true, timing: true] }
    end

    context 'with a single package' do
      let(:brew_config) { { packages: 'imagemagick' } }
      let(:brewfile) { <<~BREWFILE }
brew 'imagemagick'
      BREWFILE

      it { should include_sexp [:file, ['~/.Brewfile', brewfile]] }
      it { should include_sexp [:cmd, 'rvm $brew_ruby do brew bundle --verbose --global', echo: true, timing: true] }
    end
  end

  context 'with casks' do
    before do
      addon.before_before_install
    end

    it { should_not include_sexp [:cmd, 'rvm $brew_ruby do brew update', echo: true, timing: true] }

    context 'with multiple casks' do
      let(:brew_config) { { casks: ['google-chrome', 'firefox'] } }
      let(:brewfile) { <<~BREWFILE }
cask 'google-chrome'
cask 'firefox'
      BREWFILE

      it { should include_sexp [:file, ['~/.Brewfile', brewfile]] }
      it { should include_sexp [:cmd, 'rvm $brew_ruby do brew bundle --verbose --global', echo: true, timing: true] }
    end

    context 'with a single cask' do
      let(:brew_config) { { casks: 'google-chrome' } }
      let(:brewfile) { <<~BREWFILE }
cask 'google-chrome'
      BREWFILE

      it { should include_sexp [:file, ['~/.Brewfile', brewfile]] }
      it { should include_sexp [:cmd, 'rvm $brew_ruby do brew bundle --verbose --global', echo: true, timing: true] }
    end
  end

  context 'with taps' do
    before do
      addon.before_before_install
    end

    it { should_not include_sexp [:cmd, 'rvm $brew_ruby do brew update', echo: true, timing: true] }

    context 'with multiple taps' do
      let(:brew_config) { { taps: ['homebrew/cask-versions', 'heroku/brew'] } }
      let(:brewfile) { <<~BREWFILE }
tap 'homebrew/cask-versions'
tap 'heroku/brew'
      BREWFILE

      it { should include_sexp [:file, ['~/.Brewfile', brewfile]] }
      it { should include_sexp [:cmd, 'rvm $brew_ruby do brew bundle --verbose --global', echo: true, timing: true] }
    end

    context 'with a single tap' do
      let(:brew_config) { { taps: 'heroku/brew' } }
      let(:brewfile) { <<~BREWFILE }
tap 'heroku/brew'
      BREWFILE

      it { should include_sexp [:file, ['~/.Brewfile', brewfile]] }
      it { should include_sexp [:cmd, 'rvm $brew_ruby do brew bundle --verbose --global', echo: true, timing: true] }
    end
  end

  context 'when updating packages first' do
    before do
      addon.before_before_install
    end

    let(:brew_config) { { update: true } }

    it { should include_sexp [:cmd, 'rvm $brew_ruby do brew update 1>/dev/null', echo: true, timing: true] }
  end

  context 'when providing a custom Brewfile' do
    before do
      addon.before_before_install
    end

    context 'when using the default location' do
      let(:brew_config) { { brewfile: true } }

      it { should include_sexp [:cmd, 'rvm $brew_ruby do brew bundle --verbose', echo: true, timing: true] }
      it { should_not include_sexp [:cmd, 'rvm $brew_ruby do brew bundle --verbose --global', echo: true, timing: true] }
    end

    context 'when passing true as a string' do
      let(:brew_config) { { brewfile: "true" } }

      it { should include_sexp [:cmd, 'rvm $brew_ruby do brew bundle --verbose', echo: true, timing: true] }
      it { should_not include_sexp [:cmd, 'rvm $brew_ruby do brew bundle --verbose --global', echo: true, timing: true] }
    end

    context 'when using a custom Brewfile path' do
      let(:brew_config) { { brewfile: 'My Brewfile' } }

      it { should include_sexp [:cmd, 'rvm $brew_ruby do brew bundle --verbose --file=My\ Brewfile', echo: true, timing: true] }
      it { should_not include_sexp [:cmd, 'rvm $brew_ruby do brew bundle --verbose --global', echo: true, timing: true] }
    end
  end

  context 'when using all features' do
    before do
      addon.before_before_install
    end

    let(:brew_config) do
      {
        taps: %w[homebrew/cask-versions heroku/brew],
        casks: %w[google-chrome java8],
        packages: %w[imagemagick jq heroku],
        update: true,
        brewfile: true
      }
    end
    let(:brewfile) { <<~BREWFILE }
tap 'homebrew/cask-versions'
tap 'heroku/brew'
brew 'imagemagick'
brew 'jq'
brew 'heroku'
cask 'google-chrome'
cask 'java8'
    BREWFILE

    it { should include_sexp [:cmd, 'rvm $brew_ruby do brew update 1>/dev/null', echo: true, timing: true] }
    it { should include_sexp [:file, ['~/.Brewfile', brewfile]] }
    it { should include_sexp [:cmd, 'rvm $brew_ruby do brew bundle --verbose --global', echo: true, timing: true] }
    it { should include_sexp [:cmd, 'rvm $brew_ruby do brew bundle --verbose', echo: true, timing: true] }
  end
end
