shared_examples_for 'setup apt cache' do
  let(:setup_apt_cache) { %(echo 'Acquire::http { Proxy "http://cache.example.com:80"; };' | sudo tee /etc/apt/apt.conf.d/01proxy &> /dev/null) }

  it 'sets up an apt cache if the option is enabled' do
    data[:config][:cache] = ['apt']
    data[:hosts]= { apt_cache: 'http://cache.example.com:80'}
    should include_sexp [:cmd, setup_apt_cache]
  end

  it "doesn't set up an apt cache when the cache list is empty" do
    data[:hosts]= { apt_cache: 'http://cache.example.com:80'}
    should_not include_sexp [:cmd, setup_apt_cache]
  end

  it "doesn't set up an apt cache when the host isn't set" do
    data[:config][:cache] = ['apt']
    data[:hosts] = nil
    should_not include_sexp [:cmd, setup_apt_cache]
  end
end
