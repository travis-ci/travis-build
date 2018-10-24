require 'spec_helper'

describe Travis::Build::Script::NodeJs, :sexp do
  let(:config) { { node_js: '0.10' } }
  let(:data)   { payload_for(:push, :node_js, config: config) }
  let(:script) { described_class.new(data) }
  subject      { script.sexp }
  it           { store_example }
  it           { store_example(integration: true) }

  it_behaves_like 'a bash script', integration: true do
    let(:bash_script_file) { bash_script_path(integration: true) }
  end

  it_behaves_like 'a bash script'

  it_behaves_like 'compiled script' do
    let(:code) { ['TRAVIS_LANGUAGE=node_js'] }
    let(:cmds) { ['npm test'] }
  end

  it_behaves_like 'a build script sexp'

  it 'sets TRAVIS_NODE_VERSION' do
    should include_sexp [:export, ['TRAVIS_NODE_VERSION', '0.10']]
  end

  describe 'nvm install' do
    context 'when :node_js is set in config' do
      let(:config) { { node_js: '0.9' } }
      it 'sets the version from config :node_js' do
        should include_sexp [:cmd, 'nvm install 0.9', echo: true, timing: true]
      end

      context 'when nvm install fails' do
        let(:sexp_if)      { sexp_filter(subject, [:if, '$? -ne 0'])[1] }

        it 'tries to use locally available version' do
          expect(sexp_if).to include_sexp [:cmd, 'nvm use 0.9', echo: true]
        end

        context 'when nvm use fails' do
          let(:sexp) { sexp_filter(sexp_if, [:if, '$? -ne 0'], [:then]) }

          it 'errors the build' do
            expect(sexp).to include_sexp [:cmd, 'false', assert: true]
          end
        end
      end
    end

    context 'when :node_js is not set in config' do
      let(:config) { {} }

      context 'when .nvmrc exists' do
        let(:sexp)   { sexp_filter(subject, [:if, '-f .nvmrc'], [:then]) }

        it 'sets the version from .nvmrc' do
          expect(sexp).to include_sexp [:cmd, 'nvm install $(< .nvmrc)', echo: true, timing: true]
        end

        it 'sets TRAVIS_NODE_VERSION form .nvmrc' do
          expect(sexp).to include_sexp [:export, ['TRAVIS_NODE_VERSION', '$(< .nvmrc)']]
        end
      end

      context 'when .nvmrc does not exist' do
        let(:sexp) { sexp_filter(subject, [:if, '-f .nvmrc'], [:else]) }

        it 'sets the version to 0.10' do
          expect(sexp).to include_sexp [:cmd, 'nvm install 0.10', echo: true, timing: true]
        end

        it 'sets TRAVIS_NODE_VERSION to 0.10' do
          expect(sexp).to include_sexp [:export, ['TRAVIS_NODE_VERSION', '0.10']]
        end
      end
    end
  end

  it 'announces node --version' do
    should include_sexp [:cmd, 'node --version', echo: true]
  end

  it 'announces npm --version' do
    should include_sexp [:cmd, 'npm --version', echo: true]
  end

  it 'disables the npm spinner' do
    should include_sexp [:cmd, 'npm config set spin false', assert: true]
  end

  describe 'if package.json exists' do
    let(:sexp) { sexp_find(subject, [:if, '-f package.json'], [:then]) }

    it 'installs with npm install --npm-args' do
      data[:config][:npm_args] = '--npm-args'
      expect(sexp).to include_sexp [:cmd, 'npm install --npm-args', assert: true, echo: true, retry: true, timing: true]
    end
  end

  describe 'script' do
    let(:sexp) { sexp_filter(subject, [:if, '-f package.json'])[1] }

    it 'runs npm test if package.json exists' do
      branch = sexp_find(sexp, [:then])
      expect(sexp).to include_sexp [:cmd, 'npm test', echo: true, timing: true]
    end

    it 'runs make test if no package.json exists' do
      branch = sexp_find(sexp, [:else])
      expect(sexp).to include_sexp [:cmd, 'make test', echo: true, timing: true]
    end
  end

  describe 'strict-ssl' do
    # let(:npm_set_strict_ssl) { [:cmd, 'npm conf set strict-ssl false', assert: true, echo: true] }
    let(:npm_set_strict_ssl) { [:cmd, 'npm conf set strict-ssl false', assert: true, echo: true, timing: true] }
    ['0.6', '0.6.1', '0.6.99', '0.8', '0.8.1', '0.8.99', '0.9', '0.9.1', '0.9.99'].each do |version|
      it "sets strict-ssl to false for node #{version}" do
        data[:config][:node_js] = version
        should include_sexp npm_set_strict_ssl
      end
    end

    ['0.5.99', '0.7', '0.10'].each do |version|
      it "does not set strict-ssl to false for not node #{version}" do
        data[:config][:node_js] = version
        should_not include_sexp npm_set_strict_ssl
      end
    end
  end

  it 'converts 0.1 to 0.10' do
    data[:config][:node_js] = 0.1
    expect(script.send(:version)).to eql('0.10')
  end

  context "when os is windows" do
    before :each do
      data[:config][:os] = 'windows'
    end

    describe 'nvs install' do
      it "runs nvs add" do
        expect(subject).to include_sexp [:cmd, "nvs add 0.10", assert: true, echo: true, timing: true]
      end
    end
  end
end
