shared_examples_for 'fix etc/mavenrc' do
  let(:fix_etc_mavenrc) { "test -f /etc/mavenrc && sudo sed -e 's/M2_HOME=\\(.\\+\\)$/M2_HOME=${M2_HOME:-\\1}/' -i'.bak' /etc/mavenrc" }

  it 'adds an sexp to fix /etc/mavenrc' do
    should include_sexp [:raw, fix_etc_mavenrc]
  end
end
