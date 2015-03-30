require 'faraday'
require 'json'

describe Travis::Build::Addons::Apt, :sexp do
  let(:script)            { stub('script') }
  let(:data)              { payload_for(:push, :ruby, config: { addons: { apt: config } }) }
  let(:sh)                { Travis::Shell::Builder.new }
  let(:addon)             { described_class.new(script, sh, Travis::Build::Data.new(data), config) }
  let(:config)            { {} }
  let(:source_whitelist)  { [{ alias: 'testing', sourceline: 'deb http://example.com/deb repo main' }] }
  let(:package_whitelist) { %w(git curl) }
  subject                 { sh.to_sexp }

  before :all do
    Faraday.default_adapter = :test
  end

  before do
    described_class.instance_variable_set(:@package_whitelist, nil)
    described_class.instance_variable_set(:@source_whitelist, nil)
    addon.after_prepare
  end

  context 'when the package whitelist is provided' do
    before do
      described_class.stubs(:fetch_package_whitelist).returns(package_whitelist.join("\n"))
    end

    it 'exposes a package whitelist' do
      expect(described_class.package_whitelist).to_not be_empty
    end

    it 'instances delegate package whitelist to class' do
      expect(described_class.package_whitelist.object_id).to eql(addon.send(:package_whitelist).object_id)
    end
  end

  context 'when the source whitelist is provided' do
    before do
      described_class.stubs(:fetch_source_whitelist).returns(JSON.dump(source_whitelist))
    end

    it 'exposes a source whitelist' do
      expect(described_class.source_whitelist).to_not be_empty
    end

    it 'instances delegate source whitelist to class' do
      expect(described_class.source_whitelist.object_id).to eql(addon.send(:source_whitelist).object_id)
    end
  end

  context 'when the package whitelist cannot be fetched' do
    before do
      described_class.stubs(:fetch_package_whitelist).raises(StandardError)
    end

    it 'defaults package whitelist to empty array' do
      expect(described_class.package_whitelist).to eql([])
    end
  end

  context 'when the source whitelist cannot be fetched' do
    before do
      described_class.stubs(:fetch_source_whitelist).raises(StandardError)
    end

    it 'defaults source whitelist to empty hash' do
      expect(described_class.source_whitelist).to eql({})
    end
  end
end
