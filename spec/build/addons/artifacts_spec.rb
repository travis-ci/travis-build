require 'ostruct'
require 'spec_helper'

describe Travis::Build::Addons::Artifacts, :sexp do
  let(:script) { stub('script') }
  let(:config) { { key: 'key', secret: 'secret', bucket: 'bucket', private: true } }
  let(:data)   { payload_for(:push, :ruby, config: { addons: { artifacts: config } }) }
  let(:sh)     { Travis::Shell::Builder.new }
  let(:addon)  { described_class.new(script, sh, Travis::Build::Data.new(data), config) }
  subject      { sh.to_sexp }

  before :each do
    script.stubs(bash: '# (bash here)')
    addon.validator.stubs(valid?: true)
    addon.after_header
    addon.after_after_script
  end

  it_behaves_like 'compiled script' do
    let(:code) { ['travis_artifacts_install()'] }
    let(:cmds) { ['artifacts.setup', 'artifacts upload'] }
  end

  it 'adds the artifacts install function' do
    should include_sexp [:raw, addon.bash('travis_artifacts_install')]
  end

  it 'installs the artifacts tool' do
    should include_sexp [:cmd, 'travis_artifacts_install']
  end

  describe 'with a valid config' do
    describe 'exports' do
      let(:fold) { sexp_filter(subject, [:fold, 'artifacts.setup']) }
      let(:exports) { sexp_filter(fold, [:export]) }

      it 'installs artifacts' do
        expect(fold).to include_sexp [:cmd, 'travis_artifacts_install']
      end

      it 'exports env vars' do
        expect(exports).not_to be_empty
      end

      it 'quotes env var values' do
        exports.each do |export|
          expect(export.fetch(1).fetch(1)).to match(/^".*"$/)
        end
      end
    end

    it 'runs the command' do
      # fold = sexp_filter(subject, [:fold, 'artifacts.upload'])
      # expect(fold).to include_sexp [:cmd, 'artifacts upload']
      should include_sexp [:cmd, 'artifacts upload', echo: true]
    end
  end

  describe 'with an invalid config' do
    before :each do
      addon.validator.stubs(valid?: false)
      addon.validator.stubs(errors: ['kaputt 1', 'kaputt 2'])
    end

    it 'echoes the messages' do
      addon.after_after_script
      should include_sexp [:echo, 'kaputt 1', ansi: :red], [:echo, 'kaputt 2', ansi: :red]
    end

    it 'does not run the addon' do
      subject.expects(:run).never
      addon.after_after_script
    end
  end
end
