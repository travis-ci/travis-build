#!/usr/bin/env ruby
require 'net/http'
require 'uri'

source, target, interval = ARGV
target = URI.parse(target)
interval ||= 1

file = File.open(source, 'r+')
buff = ''

post = ->(data) do
  Net::HTTP.post_form(target, log: data)
end

at_exit do
  file.close
  post.call(buff)
end

loop do
  buff << file.getc until file.eof?
  post.call(buff) unless buff.empty?
  buff.clear
  sleep interval
end

