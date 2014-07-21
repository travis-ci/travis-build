require 'spec_helper'

describe Travis::Build::Data do
  describe 'parse' do
    %w(github.com localhost some.custom.endpoint.io).each do |host|
      it "extracts the source_host from an authenticated git url #{host}" do
        data = Travis::Build::Data.new(repository: { source_url: "git@#{host}:foo/bar.git" })
        expect(data.source_host).to eq(host)
      end

      it "extracts the source_host from an anonymous git url #{host}" do
        data = Travis::Build::Data.new(repository: { source_url: "git://#{host}/foo/bar.git" })
        expect(data.source_host).to eq(host)
      end

      it "extracts the source_host from an http url #{host}" do
        data = Travis::Build::Data.new(repository: { source_url: "http://#{host}/foo/bar.git" })
        expect(data.source_host).to eq(host)
      end

      it "extracts the source_host from an https url #{host}" do
        data = Travis::Build::Data.new(repository: { source_url: "https://#{host}/foo/bar.git" })
        expect(data.source_host).to eq(host)
      end
    end
  end

  describe 'ssh_key' do
    it 'returns ssh_key from source_key as a fallback' do
      data = Travis::Build::Data.new(config: { source_key: 'foo' })
      data.ssh_key.value.should == 'foo'
      data.ssh_key.source.should be_nil
      data.ssh_key.should be_encoded
    end

    it 'returns nil if there is no ssh_key' do
      data = Travis::Build::Data.new({ config: {} })
      data.ssh_key.should be_nil
    end

    it 'returns ssh_key from api if it is available' do
      data = Travis::Build::Data.new(ssh_key: { value: 'foo', source: 'the source' })
      data.ssh_key.value.should == 'foo'
      data.ssh_key.source.should == 'the source'
    end
  end

  describe 'cache' do
    subject(:data) { Travis::Build::Data.new(config: { cache: cache }) }

    describe "single value" do
      let(:cache) { 'bundler' }

      describe '#cache' do
        subject { super().cache }
        it { is_expected.to eq({ bundler: true }) }
      end
      it { is_expected.to be_cache(:bundler) }
      it { is_expected.not_to be_cache(:edge) }
    end

    describe "array value" do
      let(:cache) { ['bundler', 'edge'] }

      describe '#cache' do
        subject { super().cache }
        it { is_expected.to eq({ bundler: true, edge: true }) }
      end
      it { is_expected.to be_cache(:bundler) }
      it { is_expected.to be_cache(:edge) }
    end

    describe "hash value" do
      let(:cache) {{ bundler: true, edge: false }}

      describe '#cache' do
        subject { super().cache }
        it { is_expected.to eq({ bundler: true, edge: false }) }
      end
      it { is_expected.to be_cache(:bundler) }
      it { is_expected.not_to be_cache(:edge) }
    end

    describe "hash value with strings" do
      let(:cache) {{ "bundler" => true, "edge" => false }}

      describe '#cache' do
        subject { super().cache }
        it { is_expected.to eq({ bundler: true, edge: false }) }
      end
      it { is_expected.to be_cache(:bundler) }
      it { is_expected.not_to be_cache(:edge) }
    end

    describe "false" do
      let(:cache) { false }

      describe '#cache' do
        subject { super().cache }
        it { is_expected.to eq({ bundler: false, apt: false }) }
      end
      it { is_expected.not_to be_cache(:bundler) }
      it { is_expected.not_to be_cache(:edge) }
    end
  end
end
