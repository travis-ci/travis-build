require 'spec_helper'

describe Travis::Build::Script::Ruby, :sexp do
  let(:data)   { payload_for(:push, :ruby) }
  let(:script) { described_class.new(data) }
  subject      { script.sexp }
  it           { store_example }

  it_behaves_like 'compiled script' do
    let(:code) { ['TRAVIS_LANGUAGE=ruby'] }
    let(:cmds) { ['bundle install', 'bundle exec rake'] }
  end

  it_behaves_like 'a build script sexp'

  describe 'using a jdk' do
    before { data[:config][:jdk] = 'openjdk7' }
    it_behaves_like 'a jdk build sexp'
  end

  describe 'not using a jdk' do
    it 'does not announce java' do
      expect(subject.flatten.join).not_to include('java')
    end
  end

  it 'sets TRAVIS_RUBY_VERSION' do
    should include_sexp [:export, ['TRAVIS_RUBY_VERSION', 'default']]
  end

  describe 'uses rvm if config does not have a :ruby key set' do
    it 'announces rvm --version' do
      should include_sexp [:cmd, 'rvm --version', echo: true]
    end

    it 'sets the version from config :rvm (handles float values correctly)' do
      data[:config][:rvm] = 2.0
      should include_sexp [:cmd, 'rvm use 2.0 --install --binary --fuzzy', assert: true, echo: true, timing: true]
    end

    it 'sets up rvm from .ruby-version' do
      sexp = sexp_find(subject, [:if, '-f .ruby-version'], [:then])
      expect(sexp).to include_sexp [:cmd, 'rvm use $(< .ruby-version) --install --binary --fuzzy"', assert: true, echo: true, timing: true]
    end

    it 'sets the default ruby otherwise' do
      sexp = sexp_find(subject, [:if, '-f .ruby-version'], [:else])
      should include_sexp [:cmd, 'rvm use default', assert: true, echo: true, timing: true]
    end
  end

  describe 'uses chruby if config has a :ruby key set' do
    before do
      data[:config][:ruby] = '2.1.1'
    end

    it 'announces the chruby version' do
      should include_sexp [:cmd, 'chruby --version', echo: true]
    end

    it 'uses chruby to set the version' do
      # should include_sexp [:cmd, 'chruby 2.1.1', assert: true, echo: true]
      should include_sexp [:cmd, 'chruby 2.1.1', assert: true, echo: true, timing: true]
    end
  end

  it 'sets BUNDLE_GEMFILE if a gemfile exists' do
    sexp = sexp_find(subject, [:if, '-f Gemfile'], [:then])
    expect(sexp).to include_sexp [:export, ['BUNDLE_GEMFILE', '$PWD/Gemfile'], echo: true]
  end

  it 'sets BUNDLE_GEMFILE from config' do
    data[:config][:gemfile] = 'Gemfile.ci'
    should include_sexp [:export, ['BUNDLE_GEMFILE', '$PWD/Gemfile.ci'], echo: true]
  end

  it 'announces ruby --version' do
    should include_sexp [:cmd, 'ruby --version', echo: true]
  end

  it 'announces rvm --version' do
    should include_sexp [:cmd, 'rvm --version', echo: true]
  end

  it 'announces bundle --version' do
    should include_sexp [:cmd, 'bundle --version', echo: true]
  end

  describe 'install' do
    it 'runs bundle install --deployment if there is a Gemfile and a Gemfile.lock' do
      sexp = sexp_find(sexp_filter(subject, [:if, '-f Gemfile'])[1], [:if, '-f Gemfile.lock'], [:then])
      expect(sexp).to include_sexp [:cmd, 'bundle install --jobs=3 --retry=3 --deployment', assert: true, echo: true, timing: true, retry: true]
    end

    it "runs bundle install if a Gemfile exists" do
      sexp = sexp_find(sexp_filter(subject, [:if, '-f Gemfile'])[1], [:if, '-f Gemfile.lock'], [:else])
      should include_sexp [:cmd, 'bundle install --jobs=3 --retry=3', assert: true, echo: true, timing: true, retry: true]
    end
  end

  describe 'script' do
    it 'runs bundle exec rake if a gemfile exists' do
      sexp = sexp_find(subject, [:if, '-f Gemfile'], [:then])
      should include_sexp [:cmd, 'bundle exec rake', echo: true, timing: true]
    end

    it 'runs rake if a gemfile does not exist' do
      sexp = sexp_find(subject, [:if, '-f Gemfile'], [:else])
      should include_sexp [:cmd, 'rake', echo: true, timing: true]
    end
  end

  describe '#cache_slug' do
    let(:script) { described_class.new(data) }

    describe 'default' do
      subject { script.cache_slug }
      it { is_expected.to eq('cache--rvm-default--gemfile-Gemfile') }
    end

    describe 'with custom gemfile' do
      before { data[:config][:gemfile] = 'Gemfile.ci' }
      subject { script.cache_slug }
      it { is_expected.to eq('cache--rvm-default--gemfile-Gemfile.ci') }
    end

    describe 'with custom ruby version' do
      before { data[:config][:rvm] = 'jruby' }
      subject { script.cache_slug }
      it { is_expected.to eq('cache--rvm-jruby--gemfile-Gemfile') }
    end

    describe 'with custom jdk version' do
      before { data.deep_merge!(config: { rvm: 'jruby', jdk: 'openjdk7' }) }
      subject { script.cache_slug }
      it { is_expected.to eq('cache--jdk-openjdk7--rvm-jruby--gemfile-Gemfile') }
    end
  end

  context 'when testing with rbx' do
    before :each do
      data[:config][:rvm] = 'rbx'
    end

    it 'sets autolibs to disable' do
      should include_sexp [:cmd, "rvm autolibs disable", assert: true]
    end
  end
end
