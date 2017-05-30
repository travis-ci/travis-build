shared_examples_for 'fix ~/.m2/settings.xml' do
  it 'updates ~/.m2/settings.xml' do
    should include_sexp [:cmd, "test -f ~/.m2/settings.xml && sed -i.bak -e 's|https://nexus.codehaus.org/snapshots/|https://oss.sonatype.org/content/repositories/codehaus-snapshots/|g' ~/.m2/settings.xml"]
  end
end
