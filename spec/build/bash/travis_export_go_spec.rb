describe 'travis_export_go', integration: true do
  include SpecHelpers::BashFunction

  it 'is valid bash' do
    expect(run_script('travis_export_go', '')[:truth]).to be true
  end

  it 'requires a version positional argument' do
    expect(
      run_script('travis_export_go', 'travis_export_go')[:err].read
    ).to include('Missing go version positional argument')
  end

  it 'exports TRAVIS_GO_VERSION' do
    result = run_script(
      'travis_export_go', 'travis_export_go 1.23.4 && printenv'
    )
    expect(result[:out].read).to include('TRAVIS_GO_VERSION=1.23.4')
  end

  it 'exports GIMME_GO_VERSION' do
    result = run_script(
      'travis_export_go', 'travis_export_go 1.23.4 && printenv'
    )
    expect(result[:out].read).to include('GIMME_GO_VERSION=1.23.4')
  end

  it 'defaults GOMAXPROCS=2' do
    result = run_script(
      'travis_export_go', 'travis_export_go 1.23.4 && printenv'
    )
    expect(result[:out].read).to include('GOMAXPROCS=2')
  end

  it 'does not overwrite GOMAXPROCS' do
    result = run_script(
      'travis_export_go', 'GOMAXPROCS=4 travis_export_go 1.23.4 && printenv'
    )
    expect(result[:out].read).to include('GOMAXPROCS=4')
  end
end
