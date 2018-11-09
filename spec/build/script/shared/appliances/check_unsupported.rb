shared_examples_for 'checks language support' do
  it "terminates early on windows" do
    sexp = sexp_find(subject, [:if, '"$TRAVIS_OS_NAME" = windows'])
    expect(sexp).to include_sexp([:raw, 'travis_terminate 1'])
  end
end
