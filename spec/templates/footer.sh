<%= ERB.new(File.read('lib/travis/build/script/templates/footer.sh')).result(binding) %>

echo -- env --
env
