<%= ERB.new(File.read("lib/travis/build/script/templates/#{filename}")).result(binding) %>
