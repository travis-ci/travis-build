shared_examples_for 'add github.com host key' do
  let(:add_github_host_key) { "ssh-keyscan -t rsa,dsa -H github.com 2>&1 | tee -a #{Travis::Build::HOME_DIR}/.ssh/known_hosts" }

  it 'fixes the DNS entries in /etc/resolv.conf' do
    should include_sexp [:raw, add_github_host_key]
  end
end
