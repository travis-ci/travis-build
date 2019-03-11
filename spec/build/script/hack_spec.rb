require 'spec_helper'

describe Travis::Build::Script::Hack, :sexp do
  let(:data)     { payload_for(:push, :hack) }
  let(:script)   { described_class.new(data) }
  subject(:sexp) { script.sexp }
  it             { store_example }

  it_behaves_like 'a bash script'

  it_behaves_like 'compiled script' do
    let(:code) { ['TRAVIS_LANGUAGE=hack'] }
    # let(:cmds) { ['phpunit'] }
  end

  it_behaves_like 'a build script sexp'

  it 'sets TRAVIS_HACK_VERSION' do
    should include_sexp [:export, ['TRAVIS_HACK_VERSION', 'hhvm']]
  end

  context 'with empty hack value' do
    before { data[:config][:hhvm] = nil }
    it "installs default hhvm" do
      should include_sexp [:cmd, 'sudo apt-get install -y hhvm', assert: true, timing: true, echo: true]
    end
  end

  HHVM_VERSIONS = %w(
    hhvm
  )

  HHVM_VERSIONS.each do |ver|
    context "with HHVM version #{ver}" do
      before { data[:config][:hhvm] = ver }
      it "installs default hhvm" do
        should include_sexp [:cmd, "sudo apt-get install -y #{ver}", assert: true, timing: true, echo: true]
      end
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
