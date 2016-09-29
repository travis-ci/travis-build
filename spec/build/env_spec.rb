require 'spec_helper'

describe Travis::Build::Env do
  let(:payload) do
    {
      pull_request: '100',
      config: { env: ['FOO=foo', 'SECURE BAR=bar'] },
      build: { id: '1', number: '1' },
      job: { id: '1', number: '1.1', branch: 'foo-(dev)', commit: '313f61b', commit_range: '313f61b..313f61a', commit_message: 'the commit message', os: 'linux' },
      repository: { slug: 'travis-ci/travis-ci' },
      env_vars: [
        { name: 'BAM', value: 'bam', public: true },
        { name: 'BAZ', value: 'baz', public: false },
      ]
    }
  end

  let(:data) { Travis::Build::Data.new(payload) }
  let(:env)  { described_class.new(data) }
  let(:vars) { env.groups.flat_map(&:vars) }
  let(:keys) { vars.map(&:key) }

  it 'includes travis env vars' do
    travis_vars = vars.select { |v| v.key =~ /^TRAVIS_/ }
    expect(travis_vars.length).to eq(17)
  end

  describe 'config env vars' do
    let(:vars) { super().select { |var| var.type == :config } }

    it 'includes non-secure vars' do
      expect(keys).to include('FOO')
    end

    describe 'for secure env jobs' do
      before { payload[:job][:secure_env_enabled] = true }

      it 'includes secure vars' do
        expect(keys).to include('BAR')
      end

      it 'marks secure vars as secure' do
        expect(vars.last).to be_secure
      end

      it 'taints secure var values' do
        expect(vars.last.value).to be_tainted
      end
    end

    describe 'for non-secure env jobs (pull requests)' do
      before { payload[:job][:secure_env_enabled] = false }

      it 'does not include secure vars' do
        expect(keys).to_not include('BAR')
      end
    end
  end

  describe 'settings env vars' do
    let(:vars) { super().select { |var| var.type == :settings } }

    it 'includes non-secure vars' do
      expect(keys).to include('BAM')
    end

    describe 'for secure env jobs' do
      before { payload[:job][:secure_env_enabled] = true }

      it 'includes secure vars' do
        expect(keys).to include('BAZ')
      end

      it 'marks secure vars as secure' do
        expect(vars.last).to be_secure
      end

      it 'taints secure var values' do
        expect(vars.last.value).to be_tainted
      end
    end

    describe 'for non-secure env jobs (pull requests)' do
      before { payload[:job][:secure_env_enabled] = false }

      it 'does not include secure vars' do
        expect(keys).to_not include('BAZ')
      end
    end
  end

  it 'escapes TRAVIS_ vars' do
    expect(vars.find { |var| var.key == 'TRAVIS_BRANCH' }.value).to eq('foo-\(dev\)')
  end

  describe 'TRAVIS_BUILD_DIR' do
    it 'does not escape $HOME' do
      expect(vars.find {|var| var.key == 'TRAVIS_BUILD_DIR'}.value).to eq('$HOME/build/travis-ci/travis-ci')
    end

    it 'escapes the repository slug' do
      payload[:repository][:slug] = 'travis-ci/travis-ci ci'
      expect(vars.find {|var| var.key == 'TRAVIS_BUILD_DIR'}.value).to eq('$HOME/build/travis-ci/travis-ci\ ci')
    end
  end
end
