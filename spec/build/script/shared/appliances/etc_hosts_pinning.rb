shared_examples_for '/etc/hosts pinning' do
  before do
    ENV['ETC_HOSTS_PINNING'] = '127.0.0.1 foo,0.0.0.0 bar'
  end

  it 'writes to /etc/hosts' do
    should include_sexp [:raw, 'echo 127.0.0.1\\ foo | sudo tee -a /etc/hosts &>/dev/null']
    should include_sexp [:raw, 'echo 0.0.0.0\\ bar | sudo tee -a /etc/hosts &>/dev/null']
  end
end
