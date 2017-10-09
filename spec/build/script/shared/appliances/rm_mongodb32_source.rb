shared_examples_for 'remove mongodb 3.2 source' do
  it 'adds an entry to /etc/hosts for localhost' do
    should include_sexp [:cmd, 'rm -f /etc/apt/sources.list.d/mongodb-3.2.list', echo: false, assert: false, sudo: true]
  end
end
