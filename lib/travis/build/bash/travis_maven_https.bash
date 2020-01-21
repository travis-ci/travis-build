travis_maven_https() {
  if [[ ! -f $HOME/.m2/settings.xml ]]; then return; fi

  ruby -rrexml/document -e "doc=REXML::Document.new(File.read('$HOME/.m2/settings.xml'));
    doc.get_elements('//url[starts-with(.,\"http://\")]').each do |e|
      url = e.text
      e.text = url.gsub('http://','https://')
    end
    doc.write" >settings.xml
  mv settings.xml "${HOME}"/.m2/settings.xml
}
