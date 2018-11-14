require 'spec_helpers/bash_function'

describe 'travis_temporary_hacks', integration: true do
  include SpecHelpers::BashFunction

  it 'is valid bash' do
    expect(run_script('travis_temporary_hacks', '')[:truth]).to be true
  end

  %w[
    linux
    osx
    windows
    notset
  ].each do |os_name|
    it "can run successfully on os=#{os_name}" do
      expect(
        run_script(
          'travis_temporary_hacks',
          "TRAVIS_OS_NAME=#{os_name} travis_temporary_hacks"
        )[:truth]
      ).to be true
    end
  end
end
