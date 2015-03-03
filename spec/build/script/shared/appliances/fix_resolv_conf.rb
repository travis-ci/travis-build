shared_examples_for 'fix resolve.conf' do
  let(:resolv_conf_data) { <<-EOF }
options rotate
options timeout:1

nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 208.67.222.222
nameserver 208.67.220.220
  EOF
  let(:fix_resolv_conf) { "echo \"#{resolv_conf_data}\" | sudo tee /etc/resolv.conf &> /dev/null" }

  it 'fixes the DNS entries in /etc/resolv.conf' do
    should include_sexp [:raw, fix_resolv_conf]
  end

  it 'skips fixing the DNS entries in /etc/resolv.conf if told to' do
    data[:skip_resolv_updates] = true
    should_not include_sexp [:raw, fix_resolv_conf]
  end

  it 'skips fixing the DNS entries in /etc/resolv.conf if fix_resolv_conf=false' do
    data[:fix_resolv_conf] = false
    should_not include_sexp [:raw, fix_resolv_conf]
  end
end
