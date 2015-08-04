shared_examples_for 'fix etc/mavenrc' do
  let(:fix_m2_home) { "test -f /etc/mavenrc && sudo sed -e 's/M2_HOME=\\(.\\+\\)$/M2_HOME=${M2_HOME:-\\1}/' -i'.bak' /etc/mavenrc" }
  let(:fix_maven_opts) { "test -f /etc/mavenrc && sudo sed -e 's/MAVEN_OPTS=\\(.\\+\\)$/MAVEN_OPTS=${MAVEN_OPTS:-\\1}/' -i'.bak' /etc/mavenrc" }

  it 'adds an sexp to fix /etc/mavenrc' do
    should include_sexp [:raw, fix_m2_home]
    should include_sexp [:raw, fix_maven_opts]
  end
end
