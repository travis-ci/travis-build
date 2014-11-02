shared_examples_for 'fix etc/hosts' do
  let(:fix_etc_hosts) { "sudo sed -e 's/^\\(127\\.0\\.0\\.1.*\\)$/\\1 '`hostname`'/' -i'.bak' /etc/hosts" }

  it 'adds an entry to /etc/hosts for localhost' do
    should include_sexp [:cmd, fix_etc_hosts]
  end

  it 'skips adding an entry to /etc/hosts for localhost' do
    data[:skip_etc_hosts_fix] = true
    should_not include_sexp [:cmd, fix_etc_hosts]
  end
end
