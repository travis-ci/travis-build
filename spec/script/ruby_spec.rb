require 'spec_helper'

describe Travis::Build::Script::Ruby do
  let(:options) { { logs: { build: false, state: false } } }
  let(:data)    { PAYLOADS[:push].deep_clone }

  subject(:script) { described_class.new(data, options).compile }

  after :all do
    store_example
  end

  it_behaves_like 'a build script'

  it 'sets TRAVIS_RUBY_VERSION' do
    is_expected.to set 'TRAVIS_RUBY_VERSION', 'default'
  end

  it 'sets the default ruby if no :rvm config given' do
    is_expected.to travis_cmd 'rvm use default'
  end

  context 'with a .ruby-version' do
    before do
      file '.ruby-version'
    end

    it 'sets up rvm with .ruby-version' do
      is_expected.to travis_cmd 'rvm use . --install --binary --fuzzy'
    end
  end

  it 'sets the ruby from config :rvm' do
    data['config']['rvm'] = 'rbx'
    is_expected.to travis_cmd 'rvm use rbx --install --binary --fuzzy', echo: true, timing: true, assert: true
  end

  it 'handles float values correctly for rvm values' do
    data['config']['rvm'] = 2.0
    is_expected.to travis_cmd 'rvm use 2.0 --install --binary --fuzzy', echo: true, timing: true, assert: true
  end

  it 'sets BUNDLE_GEMFILE if a gemfile exists' do
    gemfile 'Gemfile.ci'
    is_expected.to travis_cmd 'export BUNDLE_GEMFILE=$PWD/Gemfile.ci', echo: true
  end

  it 'announces ruby --version' do
    is_expected.to announce 'ruby --version'
  end

  it 'announces rvm --version' do
    is_expected.to announce 'rvm --version'
  end

  it 'announces bundle --version' do
    is_expected.to announce 'bundle --version'
  end

  it 'installs with bundle install with the given bundler_args if a gemfile exists' do
    gemfile 'Gemfile.ci'
    is_expected.to travis_cmd 'bundle install --jobs=3 --retry=3', echo: true, timing: true, assert: true, retry: true
  end

  it 'folds bundle install if a gemfile exists' do
    gemfile 'Gemfile.ci'
    is_expected.to fold 'bundle install --jobs=3 --retry=3', 'install'
  end

  it "retries bundle install if a Gemfile exists" do
    gemfile "Gemfile.ci"
    is_expected.to travis_cmd 'bundle install --jobs=3 --retry=3', echo: true, timing: true, assert: true, retry: true
  end

  it 'runs bundle install --deployment if there is a Gemfile.lock' do
    gemfile('Gemfile')
    file('Gemfile.lock')
    is_expected.to travis_cmd 'bundle install --jobs=3 --retry=3 --deployment', echo: true, timing: true, assert: true, retry: true
  end

  it 'runs bundle install --deployment if there is a custom Gemfile.ci.lock' do
    gemfile('Gemfile.ci')
    file('Gemfile.ci.lock')
    is_expected.to travis_cmd 'bundle install --jobs=3 --retry=3 --deployment', echo: true, timing: true, assert: true, retry: true
  end

  it 'runs bundle exec rake if a gemfile exists' do
    gemfile 'Gemfile.ci'
    is_expected.to travis_cmd 'bundle exec rake', echo: true, timing: true
  end

  it 'runs rake if a gemfile does not exist' do
    is_expected.to travis_cmd 'rake', echo: true, timing: true
  end

  describe 'using a jdk' do
    before :each do
      data['config']['jdk'] = 'openjdk7'
    end

    after :each do
      store_example 'ruby_with_jdk'
    end

    it_behaves_like 'a jdk build'
  end

  describe 'not using a jdk' do
    it 'does not announce java' do
      is_expected.not_to announce 'java'
    end

    it 'does not announce javac' do
      is_expected.not_to announce 'javac'
    end
  end

  describe '#cache_slug' do
    subject { described_class.new(data, options) }

    describe '#cache_slug' do
      subject { super().cache_slug }
      it { is_expected.to eq('cache--rvm-default--gemfile-Gemfile') }
    end

    describe 'with custom gemfile' do
      before { gemfile 'foo' }

      describe '#cache_slug' do
        subject { super().cache_slug }
        it { is_expected.to eq('cache--rvm-default--gemfile-foo') }
      end
    end

    describe 'with custom ruby version' do
      before { data['config']['rvm'] = 'jruby' }

      describe '#cache_slug' do
        subject { super().cache_slug }
        it { is_expected.to eq('cache--rvm-jruby--gemfile-Gemfile') }
      end
    end

    describe 'with custom jdk version' do
      before do
        data['config']['rvm'] = 'jruby'
        data['config']['jdk'] = 'openjdk7'
      end

      describe '#cache_slug' do
        subject { super().cache_slug }
        it { is_expected.to eq('cache--jdk-openjdk7--rvm-jruby--gemfile-Gemfile') }
      end
    end
  end

  context 'with the ruby key set' do
    before do
      data['config']['ruby'] = '2.1.1'
    end

    it 'uses chruby to set the version' do
      is_expected.to travis_cmd 'chruby 2.1.1'
    end

    it 'announces the chruby version' do
      is_expected.to announce 'chruby --version'
    end
  end
end
