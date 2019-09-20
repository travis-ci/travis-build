describe 'travis_getaddrinfo', integration: true do
  include SpecHelpers::BashFunction

  it 'is valid bash' do
    expect(run_script('travis_getaddrinfo', '')[:truth]).to be true
  end

  it 'can run successfully' do
    result = run_script(
      'travis_getaddrinfo',
      'travis_getaddrinfo www.google.com',
      image: 'ruby:2.4.2',
    )
    expect(result[:truth]).to be true
    response = result[:out].read.strip.split($NL).first
    expect(response).to_not be_nil
    expect(response).to_not be_empty
    expect(Addrinfo.tcp(response, 80).ip?).to be true
  end
end
