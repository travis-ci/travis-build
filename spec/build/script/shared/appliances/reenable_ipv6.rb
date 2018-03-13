shared_examples_for 'reenables IPv6' do
  let(:sexp) { sexp_find(subject, [:if, '-f /etc/sysctl.d/99-travis-disable-ipv6']) }

  it "does not reenable IPv6 by default" do
    should_not include_sexp([:if, '-f /etc/sysctl.d/99-travis-disable-ipv6'])
  end

  it 'opts in to reenable IPv6' do
    data[:enable_ipv6] = true
    expect(sexp).to include_sexp([:cmd, "sudo sysctl net.ipv6.conf.all.disable_ipv6=0", echo: true])
    store_example("reenable-ipv6")
  end
end
