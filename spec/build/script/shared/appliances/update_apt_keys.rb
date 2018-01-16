shared_examples_for 'update expired apt keys' do
  it 'updates expired apt keys' do
    should include_sexp [:cmd, 'apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv', echo: false, assert: false, sudo: true]
  end
end
