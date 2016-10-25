shared_examples_for 'removes IPv6 addresses from /etc/hosts' do
  let(:no_ipv6_localhost) { "sudo sed -e 's/^\\([0-9a-f:]\\+\\) localhost/\\1/' -i'.bak' /etc/hosts" }

  it 'removes localhost from IPv6 addresses in /etc/hosts' do
    should include_sexp [:raw, no_ipv6_localhost]
  end

  context "when sudo is unavailable" do
    before { data[:paranoid] = true }
    it 'does not remove localhost from IPv6 addresses in /etc/hosts' do
      should_not include_sexp [:raw, no_ipv6_localhost]
    end
  end
end
