describe 'travis_script_go', integration: true do
  include SpecHelpers::BashFunction

  let :script_header do
    <<~BASH
      apk add --no-cache grep

      travis_cmd() {
        TRAVIS_CMD_RAN+=("${*}")
      }
      TRAVIS_CMD_RAN=()

      source /tmp/tbb/travis_has_makefile.bash
      source /tmp/tbb/__travis_go_functions.bash

      export TRAVIS_BUILD_DIR=/var/tmp/build
      mkdir -p "${TRAVIS_BUILD_DIR}"
    BASH
  end

  it 'is valid bash' do
    expect(run_script('travis_script_go', '')[:truth]).to be true
  end

  it 'runs make when a makefile is present' do
    result = run_script(
      'travis_script_go',
      <<~BASH
      #{script_header}

      touch ${TRAVIS_BUILD_DIR}/Makefile

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
      #{script_header}

      travis_script_go -v

      echo "${TRAVIS_CMD_RAN[@]}"
      BASH
    )

    expect(result[:err].read.strip).to eq ''
    expect(result[:out].read).to match(/\bgo test -v \.\/\.\.\./)
  end
end
