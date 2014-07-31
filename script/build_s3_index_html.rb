#!/usr/bin/env ruby

require 'erb'

filenames = Dir['examples/*.sh.txt']
filenames = filenames.map { |filename| filename.sub('examples/', '') }

erb = ERB.new(File.read('examples/index.html'))
puts erb.result(binding)
