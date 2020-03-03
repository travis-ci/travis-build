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
    env = Hash[output.lines.map { |l| l.split('=', 2) }]

    {
      'ANSI_CLEAR' => /.+/,
      'ANSI_GREEN' => /.+/,
      'ANSI_RED' => /.+/,
      'ANSI_RESET' => /.+/,
      'ANSI_YELLOW' => /.+/,
      'DEBIAN_FRONTEND' => /^noninteractive$/,
      'SHELL' => /.+/,
      'TERM' => /xterm/,
      'TRAVIS_ARCH' => /(amd64|386)/,
      'TRAVIS_CMD' => nil,
      'TRAVIS_DIST' => /notset/,
      'TRAVIS_INFRA' => /unknown/,
      'TRAVIS_INIT' => /(upstart|systemd|notset)/,
      'TRAVIS_OS_NAME' => /linux/,
      'TRAVIS_TEST_RESULT' => nil,
      'TRAVIS_TMPDIR' => /.+/,
      'TRAVIS_CPU_ARCH' => /(amd64|386)/,
      'USER' => /^travis$/
    }.each do |env_var, expected_value|
      expect(env.key?(env_var)).to be true
      next if expected_value.nil?
      expect(env.fetch(env_var)).to match(expected_value),
        "mismatched value for #{env_var}"
    end
  end

  it 'creates TRAVIS_TMPDIR' do
    result = run_script(
      'travis_setup_env', 'travis_setup_env && stat ${TRAVIS_TMPDIR}'
    )
    expect(result[:truth]).to be true
  end
end
