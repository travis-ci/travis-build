require 'spec_helper'

describe Travis::Build::Config do
  subject { Travis::Build.config }

  it 'defines #go_version_aliases_hash' do
    expect(subject.go_version_aliases_hash).to_not be_empty
  end

  it 'defines #ghc_version_aliases_hash' do
    expect(subject.ghc_version_aliases_hash).to_not be_empty
  end

  it 'defines .latest_semver_aliases' do
    expect(
      described_class.latest_semver_aliases(
        '1' => '1.2.3',
        '9' => '9.8.7'
      )
    ).to eq(
      '1' => '1.2.3',
      '1.x' => '1.2.3',
      '1.x.x' => '1.2.3',
      '1.2.x' => '1.2.3',
      '9' => '9.8.7',
      '9.x' => '9.8.7',
      '9.x.x' => '9.8.7',
      '9.8.x' => '9.8.7'
    )
  end
end
