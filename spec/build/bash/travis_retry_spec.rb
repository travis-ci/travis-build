describe 'travis_retry', integration: true do
  include SpecHelpers::BashFunction

  it 'is valid bash' do
    expect(run_script('travis_retry', '')[:truth]).to be true
  end

  it 'returns immediately on success' do
    expect(
      run_script('travis_retry', 'travis_retry echo whatebber')[:truth]
    ).to be true
  end

  it 'reports retries' do
    res = run_script('travis_retry', 'travis_retry cat /non/existent/file')
    expect(res[:err].read).to include('Retrying, ')
  end

  it 'reports failure after 3 attempts' do
    res = run_script('travis_retry', 'travis_retry cat /non/existent/file')
    expect(res[:err].read).to include('failed 3 times.')
  end

  it 'returns the exit code of the process that is retried' do
    res = run_script('travis_retry', 'travis_retry some-nonexistent-command')
    expect(res[:exitstatus]).to eq 127
  end
end
