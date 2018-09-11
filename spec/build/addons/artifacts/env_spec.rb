require 'spec_helper'

describe Travis::Build::Addons::Artifacts::Env do
  DISALLOWED_CONFIG = { concurrency: 0, max_size: 0, unknown: true }

  let(:data)   { payload_for(:push) }
  let(:config) do
    {
      key: 'key',
      secret: 'secret',
      bucket: 'bucket',
      private: true,
      'fizz-buzz' => 2
    }.merge(DISALLOWED_CONFIG)
  end

  subject      { described_class.new(Travis::Build::Data.new(data), config) }

  it 'prefixes $PATH with ${TRAVIS_HOME}/bin' do
    expect(subject.env['PATH']).to eql('${TRAVIS_HOME}/bin:$PATH')
  end

  it 'replaces "-" with "_" in keys prior to merge' do
    expect(subject.env['ARTIFACTS_FIZZ_BUZZ']).to eql('2')
  end

  it 'sets :key' do
    expect(subject.env['ARTIFACTS_KEY']).to eql('key')
  end

  it 'sets :secret' do
    expect(subject.env['ARTIFACTS_SECRET']).to eql('secret')
  end

  it 'sets :bucket' do
    expect(subject.env['ARTIFACTS_BUCKET']).to eql('bucket')
  end

  it 'defaults :paths to $(git ls-files -o | tr "\n" ":")' do
    expect(subject.env['ARTIFACTS_PATHS']).to eql('$(git ls-files -o | tr "\n" ":")')
  end

  it 'defaults :log_format to "multiline"' do
    expect(subject.env['ARTIFACTS_LOG_FORMAT']).to eql('multiline')
  end

  it 'defaults :target_paths to' do
    expect(subject.env['ARTIFACTS_TARGET_PATHS']).to eql("#{data[:repository][:slug]}/1/1.1")
  end

  it 'forces concurrency to 5' do
    expect(subject.env['ARTIFACTS_CONCURRENCY']).to eql('5')
  end

  it 'forces max_size to 50MB' do
    expect(subject.env['ARTIFACTS_MAX_SIZE']).to eql('52428800.0')
  end

  it 'joins values given as an array using :' do
    config[:key] = [:a, :b, :c]
    expect(subject.env['ARTIFACTS_KEY']).to eql('a:b:c')
  end
end
