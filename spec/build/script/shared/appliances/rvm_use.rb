shared_examples_for 'rvm use' do
  let(:sexp) { sexp_filter(subject, [:if, '$(command -v sw_vers)']) }
  it 'runs "rvm use"' do
    expect(sexp).to include_sexp [:cmd, "rvm use &>/dev/null"]
  end
end
