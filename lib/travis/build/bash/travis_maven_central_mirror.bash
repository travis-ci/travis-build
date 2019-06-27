travis_maven_central_mirror() {
  local google_mirror=$1
  ruby -rrexml/document -e "doc=REXML::Document.new(File.read('$HOME/.m2/settings.xml')); doc.elements['/settings'] << REXML::Document.new('<mirrors>
    <mirror>
      <id>google-maven-central</id>
      <name>GCS Maven Central mirror</name>
      <url>$google_mirror</url>
      <mirrorOf>central</mirrorOf>
    </mirror>
  </mirrors>'); doc.write" > settings.xml
  mv settings.xml $HOME/.m2/settings.xml
}
