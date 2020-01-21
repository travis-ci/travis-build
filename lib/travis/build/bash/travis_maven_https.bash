travis_maven_https() {
  if [[ ! -f $HOME/.m2/settings.xml ]]; then return; fi

  ruby -rrexml/document -e "begin
    doc=REXML::Document.new(File.read('$HOME/.m2/settings.xml'));
    doc.get_elements('//url[starts-with(.,\"http://\")]').each do |e|
      url = e.text
      e.text = url.gsub('http://','https://')
    end
    doc.write
  rescue
    nil
  end" >settings.xml
  if [[ -s settings.xml ]]; then
    mv settings.xml "${HOME}"/.m2/settings.xml
  fi
}
