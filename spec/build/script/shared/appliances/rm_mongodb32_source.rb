shared_examples_for 'remove mongodb 3.2 source' do
  it 'removes mongodb source due to an outdated key' do
    should include_sexp [:cmd, 'rm -f /etc/apt/sources.list.d/mongodb-3.2.list', echo: false, assert: false, sudo: true]
  end
end
