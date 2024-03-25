require 'spec_helper'

describe Travis::Build::Data do
  describe 'ssh_key' do
    describe 'returns ssh_key from source_key as a fallback' do
      let(:data) { Travis::Build::Data.new(config: { source_key: Base64.encode64(TEST_PRIVATE_KEY), encoded: true }) }

      it { expect(data.ssh_key.value).to eql(TEST_PRIVATE_KEY) }
      it { expect(data.ssh_key.source).to be_nil }
      it { expect(data.ssh_key).to be_encoded }
      it { expect(data.ssh_key.fingerprint).to eq('57:78:65:c2:c9:c8:c9:f7:dd:2b:35:39:40:27:d2:40') }
      it { expect(data.ssh_key.public_key).to be_nil }
    end

    describe 'returns nil if there is no ssh_key' do
      let(:data) { Travis::Build::Data.new(config: {}) }
      it { expect(data.ssh_key).to be_nil }
    end

    describe 'returns ssh_key from api if it is available' do
      let(:data) { Travis::Build::Data.new(ssh_key: { value: TEST_PRIVATE_KEY, source: 'the source' }) }
      it { expect(data.ssh_key.value).to eql(TEST_PRIVATE_KEY) }
      it { expect(data.ssh_key.source).to eql('the source') }
      it { expect(data.ssh_key).to_not be_encoded }
      it { expect(data.ssh_key.fingerprint).to eq('57:78:65:c2:c9:c8:c9:f7:dd:2b:35:39:40:27:d2:40') }
    end

    context 'when public key is provided' do
      let(:public_key) { 'ssh-rsa public-key' }
      let(:data) { Travis::Build::Data.new(ssh_key: { value: TEST_PRIVATE_KEY, public_key: public_key, source: 'the source' }) }

      it { expect(data.ssh_key.value).to eql(TEST_PRIVATE_KEY) }
      it { expect(data.ssh_key.public_key).to eql(public_key) }
    end

    describe 'does not fail on an invalid key' do
      let(:data) { Travis::Build::Data.new(config: { source_key: 'foo' }) }
      it { expect { data }.to_not raise_error }
      it { expect(data.ssh_key.fingerprint).to be_nil }
    end
  end

  describe 'cache' do
    subject(:data) { Travis::Build::Data.new(config: { cache: cache }) }

    describe 'single value' do
      let(:cache) { 'bundler' }

      it { should be_cache(:bundler) }
      it { is_expected.not_to be_cache(:edge) }
      it { expect(data.cache).to eq(bundler: true) }
    end

    describe 'array value' do
      let(:cache) { ['bundler', 'edge'] }

      it { should be_cache(:bundler) }
      it { should be_cache(:edge) }
      it { expect(data.cache).to eq(bundler: true, edge: true) }
    end

    describe 'hash value' do
      let(:cache) {{ bundler: true, edge: false }}

      it { should be_cache(:bundler) }
      it { is_expected.not_to be_cache(:edge) }
      it { expect(data.cache).to eq(bundler: true, edge: false) }
    end

    describe 'hash value with strings' do
      let(:cache) {{ 'bundler' => true, 'edge' => false }}

      it { should be_cache(:bundler) }
      it { is_expected.not_to be_cache(:edge) }
      it { expect(data.cache).to eq(bundler: true, edge: false) }
    end

    describe 'false' do
      let(:cache) { false }

      it { is_expected.not_to be_cache(:bundler) }
      it { is_expected.not_to be_cache(:edge) }
      it { expect(data.cache).to eq(bundler: false, cocoapods: false, composer: false, npm: false, ccache: false, pip: false) }
    end
  end

  describe 'installation' do
    let(:config) { { repository: { installation_id: 1, source_url: 'https://github.com/foo/bar', vcs_id: 123 } } }
    let(:data) { Travis::Build::Data.new(config) }

    before { Travis::GithubApps.any_instance.stubs(:access_token).returns 'access_token' }

    it { expect(data.installation?).to be true }
    it { expect(data.token).to eq 'access_token' }
  end

  describe 'source_ssh' do
    describe 'source_ssh for GHE force_private' do
      let(:config) { { oauth_token: 'access_token', prefer_https: false, repository: { vcs_type: 'GithubRepository', source_host: 'test.ghe.com', vcs_id: 123 } } }
      let(:data) { Travis::Build::Data.new(config) }

      before { Travis::GithubApps.any_instance.stubs(:access_token).returns 'access_token' }

      it { expect(data.source_ssh?).to be true }
      it { expect(data.token).to eq 'access_token' }
    end

    describe 'source_ssh for private' do
      let(:config) { { oauth_token: 'access_token', prefer_https: false, repository: { private: true, vcs_id: 123 } } }
      let(:data) { Travis::Build::Data.new(config) }

      before { Travis::GithubApps.any_instance.stubs(:access_token).returns 'access_token' }

      it { expect(data.source_ssh?).to be true }
      it { expect(data.token).to eq 'access_token' }
    end

    describe 'source_ssh is false for public' do
      let(:config) { { oauth_token: 'access_token', repository: { installation_id: 1, vcs_id: 123 } } }
      let(:data) { Travis::Build::Data.new(config) }

      before { Travis::GithubApps.any_instance.stubs(:access_token).returns 'access_token' }

      it { expect(data.source_ssh?).to be nil }
      it { expect(data.token).to eq 'access_token' }
    end

    describe 'source_ssh is true for public enterprise repository' do
      let(:config) { {oauth_token: 'access_token', prefer_https: false, repository: { installation_id: 1, private: false, vcs_id: 123} } }
      let(:data) { Travis::Build::Data.new(config) }

      before {
        Travis::GithubApps.any_instance.stubs(:access_token).returns 'access_token'
        ENV['TRAVIS_ENTERPRISE'] = 'true'
      }
      after {
        ENV['TRAVIS_ENTERPRISE'] = nil
      }
      it { expect(data.installation?).to be true }
      it { expect(data.source_ssh?).to be false }
      it { expect(data.token).to eq 'access_token' }
    end

    describe 'source_ssh is true for public enterprise repository if custom key is present' do
      let(:config) { {oauth_token: 'access_token', prefer_https: false, repository: { installation_id: 1, private: false, vcs_id: 123}, ssh_key: { value: TEST_PRIVATE_KEY, source: 'repository_settings' } } }
      let(:data) { Travis::Build::Data.new(config) }

      before {
        Travis::GithubApps.any_instance.stubs(:access_token).returns 'access_token'
        ENV['TRAVIS_ENTERPRISE'] = 'true'
      }
      after {
        ENV['TRAVIS_ENTERPRISE'] = nil
      }
      it { expect(data.installation?).to be true }
      it { expect(data.source_ssh?).to be true }
      it { expect(data.token).to eq 'access_token' }
    end
  end
end
