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
      let(:options) { { fetch_timeout: 20, push_timeout: 30, type: 's3', s3: { bucket: 's3_bucket', secret_access_key: 's3_secret_access_key', access_key_id: 's3_access_key_id' } } }
      let(:data)   { payload_for(:push, :node_js, config: { node_js: node_js, cache: 'npm' }, cache_options: options) }
      let(:node_js) { '8' }

      it 'sets the version from config :node_js' do
        should include_sexp [:cmd, 'nvm install 8', echo: true, timing: true]
      end

      context 'add cache by default' do
        it 'adds node_modules to directory cache' do
          should include_sexp [:cmd, "rvm $(travis_internal_ruby) --fuzzy do $CASHER_DIR/bin/casher --name cache-#{CACHE_SLUG_EXTRAS}--node-8 cache add node_modules", timing: true]
        end
      end

      context 'when cache is set to false' do
        let(:data)   { payload_for(:push, :node_js, config: { node_js: '0.9', cache: { npm: false } }) }
        it 'does not cache npm' do
          should_not include_sexp [:cmd, "rvm $(travis_internal_ruby) --fuzzy do $CASHER_DIR/bin/casher --name cache-#{CACHE_SLUG_EXTRAS}--node-8 cache add node_modules", timing: true]
        end
      end

      context 'when nvm install fails' do
        let(:sexp_if)      { sexp_filter(subject, [:if, '$? -ne 0'])[0] }

        it 'tries to use locally available version' do
          expect(sexp_if).to include_sexp [:cmd, 'nvm use 8', echo: true]
        end

        context 'when nvm use fails' do
          let(:sexp) { sexp_filter(sexp_if, [:if, '$? -ne 0'], [:then]) }

          it 'errors the build' do
            expect(sexp).to include_sexp [:cmd, 'false', assert: true]
          end
        end
      end

      context 'when node given is < 1.0' do
        let(:node_js) { '0.8' }
        it 'sends nvm install STDERR to /dev/null' do
          should include_sexp [:cmd, 'nvm install 0.8 2>/dev/null', echo: true, timing: true]
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
