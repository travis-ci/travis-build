require 'spec_helper'

describe Travis::Build::Data do
  describe 'parse' do
    %w(github.com localhost some.custom.endpoint.io).each do |host|
      describe "for #{host}" do
        let(:source_url) { "git://#{host}/foo/bar.git" }
        let(:data)       { Travis::Build::Data.new(repository: { source_url: source_url }) }

        it "extracts the source_host from an authenticated git url #{host}" do
          expect(data.source_host).to eq(host)
        end

        it "extracts the source_host from an anonymous git url #{host}" do
          expect(data.source_host).to eq(host)
        end

        it "extracts the source_host from an http url #{host}" do
          expect(data.source_host).to eq(host)
        end

        it "extracts the source_host from an https url #{host}" do
          expect(data.source_host).to eq(host)
        end
      end
    end
  end

  describe 'ssh_key' do
    describe 'returns ssh_key from source_key as a fallback' do
      let(:data) { Travis::Build::Data.new(config: { source_key: Base64.encode64(TEST_PRIVATE_KEY), encoded: true }) }

      it { expect(data.ssh_key.value).to eql(TEST_PRIVATE_KEY) }
      it { expect(data.ssh_key.source).to be_nil }
      it { expect(data.ssh_key).to be_encoded }
      it { expect(data.ssh_key.fingerprint).to eq('57:78:65:c2:c9:c8:c9:f7:dd:2b:35:39:40:27:d2:40') }
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
      it { expect(data.cache).to eq(bundler: false, cocoapods: false, composer: false, ccache: false, pip: false) }
    end
  end

  describe 'installation' do
    let(:config) { { repository: { installation_id: 1, source_url: 'https://github.com/foo/bar' } } }
    let(:data) { Travis::Build::Data.new(config) }

    before { Travis::GithubApps.any_instance.stubs(:access_token).returns 'access_token' }

    it { expect(data.installation?).to be true }
    it { expect(data.token).to eq 'access_token' }
  end
end
