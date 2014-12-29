shared_examples_for 'put localhost first in etc/hosts' do
  let(:put_localhost_first) { "sudo sed -e 's/^127\\.0\\.0\\.1\\(.*\\) localhost \\(.*\\)$/127.0.0.1 localhost \\1 \\2/' -i'.bak' /etc/hosts" }

  it 'places localhost first in /etc/hosts' do
    should include_sexp [:cmd, put_localhost_first]
  end
end
