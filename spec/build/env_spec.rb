require 'spec_helper'

describe Travis::Build::Env do
  let(:payload) do
    {
      host: 'travis-ci.com',
      pull_request: '100',
      config: { env: ['FOO=foo', 'SECURE BAR=bar'] },
      build: { id: '1', number: '1' },
      job: { id: '1', number: '1.1', branch: branch, commit: '03148a8', commit_range: '03148a8..f9da1fd', commit_message: 'the commit message', os: 'linux' },
      repository: { slug: 'travis-ci/travis-ci' },
      env_vars: [
        { name: 'BAM', value: 'bam', public: true },
        { name: 'FOODEV', value: 'foodev', public: true, branch: 'foo-(dev)' },
        { name: 'FOOMASTER', value: 'foomaster', public: true, branch: 'master' },
        { name: 'MULTIBRANCHVARIABLE', value: 'foodevvalue', public: true, branch: 'foo-(dev)' },
        { name: 'MULTIBRANCHVARIABLE', value: 'footestvalue', public: true, branch: 'foo-(test)' },
        { name: 'MULTIBRANCHVARIABLE', value: 'defaultvalue', public: true },
        { name: 'BAZ', value: 'baz', public: false },
      ]
    }
  end

  let(:data) { Travis::Build::Data.new(payload) }
  let(:env)  { described_class.new(data) }
  let(:vars) { env.groups.flat_map(&:vars) }
  let(:keys) { vars.map(&:key) }
  let(:branch) { 'foo-(dev)' }

  it 'includes travis env vars' do
    travis_vars = vars.select { |v| v.key =~ /^TRAVIS_/ }
    expect(travis_vars.length).to eq(26)
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
        expect(vars.select {|v| v.secure?}).to_not be_empty
      end

      it 'taints secure var values' do
        expect(vars.select {|v| v.secure?}.map {|x| x.value.tainted?}.uniq).to eq [true]
      end
    end

    describe 'for non-secure env jobs (pull requests)' do
      before { payload[:job][:secure_env_enabled] = false }

      it 'does not include secure vars' do
        expect(keys).to_not include('BAZ')
      end
    end

    describe 'for env jobs (pull requests) restricted to branch' do
      it 'includes vars restricted to foo-(dev) branch' do
        expect(keys).to include('FOODEV')
      end
      it 'does not include vars restricted to master branch' do
        expect(keys).to_not include('FOOMASTER')
      end
      it 'includes values restricted to foo-(dev) branch' do
        expect(vars.select {|var| var.key == 'MULTIBRANCHVARIABLE'}.last.value).to eq('foodevvalue')
      end
      it 'does not include vars restricted to foo-(test) branch' do
        expect(vars.select {|var| var.key == 'MULTIBRANCHVARIABLE'}.last.value).to_not eq('footestvalue')
      end
    end

    context 'on master branch builds' do
      let(:branch) { 'master' }

      describe 'for env jobs (pull requests) restricted to branch' do
        it 'includes vars restricted to foo-(dev) branch' do
          expect(keys).to_not include('FOODEV')
        end
        it 'does includes vars restricted to master branch' do
          expect(keys).to include('FOOMASTER')
        end
        it 'includes values restricted to foo-(dev) branch' do
          expect(vars.select {|var| var.key == 'MULTIBRANCHVARIABLE'}.last.value).to eq('defaultvalue')
        end
        it 'does not include vars restricted to foo-(test) branch' do
          expect(vars.select {|var| var.key == 'MULTIBRANCHVARIABLE'}.last.value).to_not eq('foodevvalue')
        end
      end
    end
  end

  it 'escapes TRAVIS_ vars' do
    expect(vars.find { |var| var.key == 'TRAVIS_BRANCH' }.value).to eq('foo-\(dev\)')
  end

  describe 'TRAVIS_BUILD_DIR' do
    it "does not escape #{Travis::Build::BUILD_DIR}" do
      expect(vars.find {|var| var.key == 'TRAVIS_BUILD_DIR'}.value).
        to eq("#{Travis::Build::BUILD_DIR}/#{payload[:repository][:slug]}")
    end

    it 'escapes the repository slug' do
      payload[:repository][:slug] = 'travis-ci/travis-ci ci'
      expect(vars.find {|var| var.key == 'TRAVIS_BUILD_DIR'}.value).
        to eq("#{Travis::Build::BUILD_DIR}/travis-ci/travis-ci\\ ci")
    end
  end
  describe '*_URL env vars' do
    it 'are set to correct value' do
      expect(vars.find {|var| var.key == 'TRAVIS_BUILD_WEB_URL'}.value).to eq('https://travis-ci.com/travis-ci/travis-ci/builds/1')
      expect(vars.find {|var| var.key == 'TRAVIS_JOB_WEB_URL'}.value).to eq('https://travis-ci.com/travis-ci/travis-ci/jobs/1')
    end
  end
end
