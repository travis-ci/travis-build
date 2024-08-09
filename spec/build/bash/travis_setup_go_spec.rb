describe 'travis_setup_go', integration: true do
  include SpecHelpers::BashFunction

  let(:go_version) { '1.22.5' }
  let(:go_import_path) { 'github.com/travis-ci-examples/go-example' }

  let :script_header do
    <<~BASH
      apk add --no-cache grep sudo

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
    expect(run_script('travis_setup_go', '')[:truth]).to be true
  end

  it 'requires TRAVIS_GO_VERSION' do
    result = run_script(
      'travis_setup_go',
      <<~BASH
      #{script_header}
      'travis_setup_go'
      BASH
    )
    expect(result[:err].read.strip).
      to include('Missing TRAVIS_GO_VERSION')
  end
end
