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

  it 'requires an import path positional argument' do
    expect(
      run_script('travis_export_go', 'travis_export_go 1.2.3')[:err].read
    ).to include('Missing go import path positional argument')
  end

  it 'exports TRAVIS_GO_VERSION' do
    result = run_script(
      'travis_export_go', 'travis_export_go 1.23.4 test.io/bim/bam && printenv'
    )
    expect(result[:out].read).to include('TRAVIS_GO_VERSION=1.23.4')
  end

  it 'exports TRAVIS_GO_IMPORT_PATH' do
    result = run_script(
      'travis_export_go', 'travis_export_go 1.23.4 test.io/bim/bam && printenv'
    )
    expect(result[:out].read).to include('TRAVIS_GO_IMPORT_PATH=test.io/bim/bam')
  end

  it 'exports GIMME_GO_VERSION' do
    result = run_script(
      'travis_export_go', 'travis_export_go 1.23.4 test.io/bim/bam && printenv'
    )
    expect(result[:out].read).to include('GIMME_GO_VERSION=1.23.4')
  end

  it 'defaults GOMAXPROCS' do
    result = run_script(
      'travis_export_go', 'travis_export_go 1.23.4 test.io/bim/bam && printenv'
    )
    expect(result[:out].read).to match(/GOMAXPROCS=./)
  end

  it 'does not overwrite GOMAXPROCS' do
    result = run_script(
      'travis_export_go', 'GOMAXPROCS=4 travis_export_go 1.23.4 test.io/bim/bam && printenv'
    )
    expect(result[:out].read).to include('GOMAXPROCS=4')
  end
end
