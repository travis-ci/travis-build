describe 'travis_whereami', integration: true do
  include SpecHelpers::BashFunction

  it 'is valid bash' do
    expect(run_script('travis_whereami', '')[:truth]).to be true
  end

  it 'can run successfully' do
    result = run_script(
      'travis_whereami',
      'apk add --no-cache curl &>/dev/null && travis_whereami'
    )

    expect(result[:truth]).to be true

    outlines = result[:out].read.lines.map(&:strip)
    expect(outlines.first).to match(/^infra=.+/)
    expect(outlines.last).to match(/^ip=.+/)
  end
end
