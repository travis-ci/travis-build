describe 'travis_preamble', integration: true do
  include SpecHelpers::BashFunction

  it 'is valid bash' do
    expect(run_script('travis_preamble', '')[:truth]).to be true
  end

  it 'can run successfully' do
    expect(run_script('travis_preamble', 'travis_preamble')[:truth]).to be true
  end

  it 'appends sourcing of job stages to ~/.bashrc' do
    result = run_script(
      'travis_preamble', 'travis_preamble && cat /home/travis/.bashrc'
    )
    expect(result[:truth]).to be true
    expect(result[:out].read).to include 'source /home/travis/.travis/job_stages'
  end

  it 'creates and changes dirs to TRAVIS_BUILD_DIR' do
    result = run_script('travis_preamble', 'travis_preamble && pwd')
    expect(result[:truth]).to be true
    expect(result[:out].read.strip).to eq '/home/travis/build/travis_preamble_spec'
  end
end
