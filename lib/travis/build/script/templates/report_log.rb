#!/usr/bin/env ruby

require 'net/http'
require 'uri'

source, target, interval = ARGV
target = URI.parse(target)
interval ||= 0.5

file = File.open(source, 'r+')
buff = ''

post = ->(data) do
  Net::HTTP.post_form(target, data)
end

at_exit do
  file.close
  post.call(final: true, log: buff)
end

loop do
  buff << file.getc until file.eof?
  post.call(log: buff) unless buff.empty?
  buff.clear
  sleep interval
end

