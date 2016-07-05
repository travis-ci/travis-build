shared_examples_for 'cleans up $PATH' do
  let(:fix_etc_hosts) { "sudo sed -e 's/^\\(127\\.0\\.0\\.1.*\\)$/\\1 '`hostname`'/' -i'.bak' /etc/hosts" }

  it 'adds an entry to /etc/hosts for localhost' do
    should include_sexp [ :export, ['PATH', "$(echo $PATH | sed -e 's/::/:/')" ] ]
  end
end