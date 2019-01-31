describe 'travis_prepare_go', integration: true do
  include SpecHelpers::BashFunction

  let :script_header do
    <<~BASH
      source /tmp/tbb/travis_download.bash
      source /tmp/tbb/travis_vers2int.bash

      gimme() {
        if [[ "${1}" == --version ]]; then
          echo "${GIMME_VERSION:-v1.2.0}"
        fi

        GIMME_COMMANDS_RUN+=("gimme ${*}")
      }

      TRAVIS_APP_HOST=https://build.travis-ci.com
      TRAVIS_HOME=/tmp
      GIMME_URL="${TRAVIS_APP_HOST}/files/gimme?source=#{__FILE__}:#{__LINE__}"
      GIMME_GO_VERSION=1.11.4
      GIMME_COMMANDS_RUN=()
    BASH
  end

  it 'is valid bash' do
    expect(run_script('travis_prepare_go', '')[:truth]).to be true
  end

  it 'requires a gimme_url positional argument' do
    result = run_script('travis_prepare_go', 'travis_prepare_go "" ""')
    expect(result[:err].read).
      to include('Missing gimme_url positional argument')
  end

  it 'requires a default_go_version positional argument' do
    result = run_script('travis_prepare_go', 'travis_prepare_go "blep" ""')
    expect(result[:err].read).
      to include('Missing default_go_version positional argument')
  end

  it 'unsets gvm' do
    result = run_script(
      'travis_prepare_go',
      <<~BASH
        #{script_header}
        gvm=nonempty
        travis_prepare_go "${GIMME_URL}" "${GIMME_GO_VERSION}"
        printenv
      BASH
    )
    expect(result[:out].read).to_not match(/^gvm=/)
  end

  it 'moves ~/.gvm' do
    result = run_script(
      'travis_prepare_go',
      <<~BASH
        #{script_header}
        mkdir -p "${TRAVIS_HOME}/.gvm"
        touch "${TRAVIS_HOME}/.gvm/something"

        travis_prepare_go "${GIMME_URL}" "${GIMME_GO_VERSION}"

        if [[ -d "${TRAVIS_HOME}/.gvm" ]]; then
          echo '~/.gvm exists' >&2
        else
          echo 'no ~/.gvm yay'
        fi
      BASH
    )
    expect(result[:err].read).to_not include('~/.gvm exists')
    expect(result[:out].read).to include('no ~/.gvm yay')
  end

  context 'when gimme>=1.5.3 is already installed' do
    it 'bootstraps the default go and warms the known version cache' do
      result = run_script(
        'travis_prepare_go',
        <<~BASH
          #{script_header}
          GIMME_VERSION=v1.5.3
          apk add --no-cache curl grep

          travis_prepare_go "${GIMME_URL}" "1.7.6"
          echo "${GIMME_COMMANDS_RUN[@]}"
        BASH
      )
      expect(result[:err].read.strip).to eq ''

      out = result[:out].read
      expect(out).to include('gimme 1.7.6')
      expect(out).to include('gimme -k')
    end
  end

  context 'when gimme<1.5.3 is already installed' do
    it 'updates gimme, bootstraps the default go, and warms the known version cache' do
      result = run_script(
        'travis_prepare_go',
        <<~BASH
          #{script_header}
          apk add --no-cache curl grep

          travis_prepare_go "${GIMME_URL}" "1.6.4"
          echo "${GIMME_COMMANDS_RUN[@]}"
          echo "gimme version: $("${TRAVIS_HOME}/bin/gimme" --version)"
        BASH
      )

      expect(result[:err].read.strip).to eq ''

      out = result[:out].read
      expect(out).to include('Updating gimme')
      expect(out).to include('gimme 1.6.4')
      expect(out).to include('gimme -k')
      expect(out).to match(/^gimme version: v[0-9]+\.[0-9]+\.[0-9]+/)
    end

    context 'when no TRAVIS_APP_HOST is set' do
      it 'updates gimme, bootstraps the default go, and warms the known version cache' do
        result = run_script(
          'travis_prepare_go',
          <<~BASH
            #{script_header}
            unset TRAVIS_APP_HOST
            apk add --no-cache curl grep

            travis_prepare_go "${GIMME_URL}" "1.6.4"
            echo "${GIMME_COMMANDS_RUN[@]}"
            echo "gimme version: $("${TRAVIS_HOME}/bin/gimme" --version)"
          BASH
        )

        expect(result[:err].read.strip).to eq ''

        out = result[:out].read
        expect(out).to include('Installing gimme from')
        expect(out).to include('gimme 1.6.4')
        expect(out).to include('gimme -k')
        expect(out).to match(/^gimme version: v[0-9]+\.[0-9]+\.[0-9]+/)
      end
    end
  end
end
