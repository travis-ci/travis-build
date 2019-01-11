describe 'travis_script_go', integration: true do
  include SpecHelpers::BashFunction

  it 'is valid bash' do
    expect(run_script('travis_script_go', '')[:truth]).to be true
  end
end
