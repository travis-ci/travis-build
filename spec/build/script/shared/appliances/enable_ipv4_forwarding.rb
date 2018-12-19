shared_examples_for 'enables ipv4 forwarding by adding a file in /etc/sysctl' do

  it 'adds a file in /etc/sysctl' do
    should include_sexp [:cmd, 'echo "net.xXXXXXXXX.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/99-travis-enable-ipv4-forwarding.conf > /dev/null', echo: false, assert: false, sudo: true]
  end

  context "when sudo is unavailable" do
    before { data[:paranoid] = true }
    it 'does not add a file in /etc/sysctl' do
      should_not include_sexp [:raw, enable_ipv4_forwarding]
    end
  end
end
