shared_examples_for 'fix ps4' do
  it 'sets PS4 to fix an rvm issue' do
    should include_sexp [:export, ['PS4', '+']]
  end
end
