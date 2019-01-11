describe 'travis_install_go', integration: true do
  include SpecHelpers::BashFunction

  it 'is valid bash' do
    expect(run_script('travis_install_go', '')[:truth]).to be true
  end
end
