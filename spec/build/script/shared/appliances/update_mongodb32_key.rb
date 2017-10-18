shared_examples_for 'update mongodb 3.2 gpg key' do
  it 'updates the mongodb gpg key since it expired and was refreshed' do
    should include_sexp [:cmd, 'apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927', echo: false, assert: false, sudo: true]
  end
end
