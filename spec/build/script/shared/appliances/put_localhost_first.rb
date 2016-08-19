shared_examples_for 'put localhost first in etc/hosts' do
  let(:put_localhost_first) { %q(grep '^127\.0\.0\.1' /etc/hosts | sed -e 's/^127\.0\.0\.1 \\(.*\\)/\1/g' | sed -e 's/localhost \\(.*\\)/\1/g' | tr "\n" " " > /tmp/hosts_127_0_0_1) }

  it 'places localhost first in /etc/hosts' do
    should include_sexp [:raw, put_localhost_first]
  end
end
