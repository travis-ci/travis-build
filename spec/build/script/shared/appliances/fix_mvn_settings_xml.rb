shared_examples_for 'fix ~/.m2/settings.xml' do
  it 'updates ~/.m2/settings.xml' do
    should include_sexp [:cmd, "sed -i$([ \"$TRAVIS_OS_NAME\" == osx ] && echo \" \").bak1 -e 's|https://nexus.codehaus.org/snapshots/|https://oss.sonatype.org/content/repositories/codehaus-snapshots/|g' ~/.m2/settings.xml"]
    should include_sexp [:cmd, "sed -i$([ \"$TRAVIS_OS_NAME\" == osx ] && echo \" \").bak2 -e 's|https://repository.apache.org/releases/|https://repository.apache.org/content/repositories/releases/|g' ~/.m2/settings.xml"]
  end
end
