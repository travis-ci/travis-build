require 'spec_helper'

describe Travis::Build::Data do
  describe 'parse' do
    %w(github.com localhost some.custom.endpoint.io).each do |host|
      it "extracts the source_host from an authenticated git url #{host}" do
        data = Travis::Build::Data.new(repository: { source_url: "git@#{host}:foo/bar.git" })
        data.source_host.should == host
      end

      it "extracts the source_host from an anonymous git url #{host}" do
        data = Travis::Build::Data.new(repository: { source_url: "git://#{host}/foo/bar.git" })
        data.source_host.should == host
      end

      it "extracts the source_host from an http url #{host}" do
        data = Travis::Build::Data.new(repository: { source_url: "http://#{host}/foo/bar.git" })
        data.source_host.should == host
      end

      it "extracts the source_host from an https url #{host}" do
        data = Travis::Build::Data.new(repository: { source_url: "https://#{host}/foo/bar.git" })
        data.source_host.should == host
      end
    end
  end

  describe 'cache' do
    subject(:data) { Travis::Build::Data.new(config: { cache: cache }) }

    describe "single value" do
      let(:cache) { 'bundler' }
      its(:cache) { should be == { bundler: true } }
      it { should be_cache(:bundler) }
      it { should_not be_cache(:edge) }
    end

    describe "array value" do
      let(:cache) { ['bundler', 'edge'] }
      its(:cache) { should be == { bundler: true, edge: true } }
      it { should be_cache(:bundler) }
      it { should be_cache(:edge) }
    end

    describe "hash value" do
      let(:cache) {{ bundler: true, edge: false }}
      its(:cache) { should be == { bundler: true, edge: false } }
      it { should be_cache(:bundler) }
      it { should_not be_cache(:edge) }
    end

    describe "hash value with strings" do
      let(:cache) {{ "bundler" => true, "edge" => false }}
      its(:cache) { should be == { bundler: true, edge: false } }
      it { should be_cache(:bundler) }
      it { should_not be_cache(:edge) }
    end

    describe "false" do
      let(:cache) { false }
      its(:cache) { should be == { bundler: false, apt: false } }
      it { should_not be_cache(:bundler) }
      it { should_not be_cache(:edge) }
    end
  end
end
