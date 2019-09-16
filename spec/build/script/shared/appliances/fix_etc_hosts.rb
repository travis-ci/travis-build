shared_examples_for 'fix etc/hosts' do
  let(:fix_etc_hosts) { "sudo sed -e 's/^\\(127\\.0\\.0\\.1.*\\)$/\\1 '`hostname`'/' -i'.bak' /etc/hosts 2> /dev/null" }

  it 'adds an entry to /etc/hosts for localhost' do
    should include_sexp [:raw, fix_etc_hosts]
  end

  it 'skips adding an entry to /etc/hosts for localhost' do
    data[:skip_etc_hosts_fix] = true
    should_not include_sexp [:raw, fix_etc_hosts]
  end

  it 'skips adding an entry to /etc/hosts for localhost if fix_etc_hosts=false' do
    data[:fix_etc_hosts] = false
    should_not include_sexp [:raw, fix_etc_hosts]
  end
end
