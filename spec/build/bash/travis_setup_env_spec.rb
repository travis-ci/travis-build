require 'spec_helpers/bash_function'

describe 'travis_setup_env', integration: true do
  include SpecHelpers::BashFunction

  it 'is valid bash' do
    expect(run_script('travis_setup_env', '')[:truth]).to be true
  end

  it 'can run successfully' do
    expect(
      run_script('travis_setup_env', 'travis_setup_env')[:truth]
    ).to be true
  end

  it 'sets expected env vars' do
    result = run_script('travis_setup_env', 'travis_setup_env && printenv')

    expect(result[:truth]).to be true

    output = result[:out].read
    expect(output.length).to be > 0

    %w[
      ANSI_CLEAR
      ANSI_GREEN
      ANSI_RED
      ANSI_RESET
      ANSI_YELLOW
      DEBIAN_FRONTEND
      SHELL
      TERM
      TRAVIS_ARCH
      TRAVIS_CMD
      TRAVIS_DIST
      TRAVIS_INFRA
      TRAVIS_INIT
      TRAVIS_OS_NAME
      TRAVIS_TEST_RESULT
      TRAVIS_TMPDIR
      USER
    ].each do |env_var|
      expect(output).to match(/^#{env_var}=/)
    end
  end

  it 'creates TRAVIS_TMPDIR' do
    result = run_script(
      'travis_setup_env', 'travis_setup_env && stat ${TRAVIS_TMPDIR}'
    )
    expect(result[:truth]).to be true
  end
end
