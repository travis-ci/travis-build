require 'spec_helper'

describe Travis::Build::Script::Addons::Artifacts::Env do
  DISALLOWED_CONFIG = { concurrency: 0, max_size: 0, target_paths: 'no', unknown: true }

  let(:data)   { Travis::Build::Data.new(PAYLOADS[:push].deep_clone) }
  let(:config) { { key: 'key', secret: 'secret', bucket: 'bucket', private: true }.merge(DISALLOWED_CONFIG) }
  subject      { described_class.new(data, config) }

  it 'prefixes $PATH with $HOME/bin' do
    expect(subject.env['PATH']).to eql('$HOME/bin:$PATH')
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

  it 'forces concurrency to 5' do
    expect(subject.env['ARTIFACTS_CONCURRENCY']).to eql('5')
  end

  it 'forces max_size to 50MB' do
    expect(subject.env['ARTIFACTS_MAX_SIZE']).to eql('52428800.0')
  end

  it 'forces target_paths to' do
    expect(subject.env['ARTIFACTS_TARGET_PATHS']).to eql('travis-ci/travis-ci/1/1.1')
  end

  it 'joins values given as an array using :' do
    config[:key] = [:a, :b, :c]
    expect(subject.env['ARTIFACTS_KEY']).to eql('a:b:c')
  end

  it 'removes any unknown keys' do
    expect(subject.env).not_to be_key('ARTIFACTS_UNKNOWN')
  end
end
