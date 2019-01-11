describe 'travis_install_go', integration: true do
  include SpecHelpers::BashFunction

  let :script_header do
    <<~BASH
      gimme() {
        if [[ "${1}" == -r ]]; then
          echo "${GIMME_GO_VERSION}"
        fi
      }

      go() {
        if [[ "${1}" == get ]]; then
          echo "----> go" "${@}"
        fi
      }

      source /tmp/tbb/travis_assert.bash
      source /tmp/tbb/travis_cmd.bash
      source /tmp/tbb/travis_nanoseconds.bash
      source /tmp/tbb/travis_retry.bash
      source /tmp/tbb/travis_time_finish.bash
      source /tmp/tbb/travis_time_start.bash
      source /tmp/tbb/travis_vers2int.bash
    BASH
  end

  it 'is valid bash' do
    expect(run_script('travis_install_go', '')[:truth]).to be true
  end

  it 'supports go 1.11+ modules' do
    result = run_script(
      'travis_install_go',
      "#{script_header} GO111MODULE=on travis_install_go 1.11.1 -v"
    )
    out = result[:out].read
    expect(result[:err].read).to eq ''
    expect(out).to include('Using Go 1.11+ Modules')
    expect(out).to_not include('Using Go 1.5 Vendoring')
    expect(out).to_not include('godep restore')
  end

  it 'supports go 1.5+ vendoring' do
    result = run_script(
      'travis_install_go',
      "#{script_header} travis_install_go 1.7.6 -v"
    )
    out = result[:out].read
    expect(result[:err].read).to eq ''
    expect(out).to_not include('Using Go 1.11+ Modules')
    expect(out).to include('Using Go 1.5 Vendoring')
    expect(out).to_not include('godep restore')
  end

  it 'supports godep' do
    result = run_script(
      'travis_install_go',
      <<~BASH
        #{script_header}
        godep() {
          if [[ "${1}" == restore ]]; then
            echo "----> godep" "${@}"
          fi
        }
        __travis_install_go_fetch_godep() {
          :
        }
        mkdir -p Godeps
        touch Godeps/Godeps.json
        travis_install_go 1.4.3 -v
      BASH
    )
    out = result[:out].read
    expect(result[:err].read).to eq ''
    expect(out).to_not include('Using Go 1.11+ Modules')
    expect(out).to_not include('Using Go 1.5 Vendoring')
    expect(out).to include('godep restore')
  end

  it 'echoes about it when a makefile is present' do
    result = run_script(
      'travis_install_go',
      <<~BASH
        #{script_header}
        touch Makefile
        travis_install_go 1.11.1 -v
      BASH
    )
    out = result[:out].read
    expect(result[:err].read).to eq ''
    expect(out).to include('Makefile detected')
  end

  it 'runs "go get" when no makefile is present' do
    result = run_script(
      'travis_install_go',
      "#{script_header} travis_install_go 1.11.1 -v"
    )
    out = result[:out].read
    expect(result[:err].read).to eq ''
    expect(out).to include('----> go get')
  end
end
