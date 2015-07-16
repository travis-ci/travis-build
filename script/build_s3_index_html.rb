#!/usr/bin/env ruby

require 'erb'

filenames = Dir['examples/*.sh.txt'].sort
filenames = filenames.map { |filename| filename.sub('examples/', '') }

path = 'examples/index.html'
erb = ERB.new(File.read(path))
File.open(path, 'w+') { |f| f.write(erb.result(binding)) }
