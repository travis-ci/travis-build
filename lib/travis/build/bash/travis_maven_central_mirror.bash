travis_maven_central_mirror() {
  local google_mirror=$1
  if [[ ! -f $HOME/.m2/settings.xml ]]; then return; fi

  ruby -rrexml/document -e "begin
    doc=REXML::Document.new(File.read('$HOME/.m2/settings.xml')); doc.elements['/settings'] << REXML::Document.new('<mirrors>
      <mirror>
        <id>google-maven-central</id>
        <name>GCS Maven Central mirror</name>
        <url>$google_mirror</url>
        <mirrorOf>central</mirrorOf>
      </mirror>
    </mirrors>')
    doc.write
  rescue
    nil
  end" >settings.xml
  if [[ -s settings.xml ]]; then
    mv settings.xml "${HOME}"/.m2/settings.xml
  fi
}
