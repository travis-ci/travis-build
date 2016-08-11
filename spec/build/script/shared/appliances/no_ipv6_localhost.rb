shared_examples_for 'fix etc/hosts' do
  let(:no_ipv6_localhost) { "sudo sed -e 's/^\\([0-9a-f:]\\+\\) localhost/\\1/' -i'.bak' /etc/hosts" }

  it 'removes localhost from IPv6 addresses in /etc/hosts' do
    should include_sexp [:raw, no_ipv6_localhost]
  end
end
