describe 'travis_script_go', integration: true do
  include SpecHelpers::BashFunction

  it 'is valid bash' do
    expect(run_script('travis_script_go', '')[:truth]).to be true
  end

  it 'runs make when a makefile is present' do
    result = run_script(
      'travis_script_go',
      <<~BASH
      travis_cmd() {
        TRAVIS_CMD_RAN+=("${*}")
      }
      TRAVIS_CMD_RAN=()
      touch Makefile

      travis_script_go -v

      echo "${TRAVIS_CMD_RAN[@]}"
      BASH
    )

    expect(result[:err].read.strip).to eq ''
    expect(result[:out].read).to match(/\bmake\b/)
  end

  it 'runs "go test" when makefile is not present' do
    result = run_script(
      'travis_script_go',
      <<~BASH
      travis_cmd() {
        TRAVIS_CMD_RAN+=("${*}")
      }
      TRAVIS_CMD_RAN=()

      travis_script_go -v

      echo "${TRAVIS_CMD_RAN[@]}"
      BASH
    )

    expect(result[:err].read.strip).to eq ''
    expect(result[:out].read).to match(/\bgo test -v \.\/\.\.\./)
  end
end
