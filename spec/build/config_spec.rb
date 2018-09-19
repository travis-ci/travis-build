require 'spec_helper'

describe Travis::Build::Config do
  subject { Travis::Build.config }

  it 'defines #ghc_version_aliases_hash' do
    expect(subject.ghc_version_aliases_hash).to_not be_empty
  end
end
