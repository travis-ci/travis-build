shared_examples_for 'fix resolve.conf' do
  let(:fix_resolv_conf) { "grep '199.91.168' /etc/resolv.conf > /dev/null || echo 'nameserver 199.91.168.70\nnameserver 199.91.168.71' | sudo tee /etc/resolv.conf &> /dev/null" }

  it 'fixes the DNS entries in /etc/resolv.conf' do
    should include_sexp [:raw, fix_resolv_conf]
  end

  it 'skips fixing the DNS entries in /etc/resolv.conf if told to' do
    data[:skip_resolv_updates] = true
    should_not include_sexp [:raw, fix_resolv_conf]
  end
end

