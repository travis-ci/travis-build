#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'json'

source, target = ARGV
target = URI.parse(target)

file = File.open(source, 'r+')
last_state, last_stage = nil, nil

post = ->(data) do
  p data
  Net::HTTP.post_form(target, data)
end

on_start = ->(line) do
  post.call(event: :start, started_at: Time.now, worker: `hostname`)
end

on_finish = ->(line, result) do
  state = last_state == 'start' ? :errored : (result == 0 ? :passed : :failed)
  data = { event: :finish, state: state, finished_at: Time.now }
  data[:error] = :"#{last_stage}_failed" if state == :errored
  post.call(data)
end

report = ->(line) do
  case line
  when /\[build:start\]/
    on_start.call(line)
  when /\[build:finish\] result: ([\d]+)/
    on_finish.call(line, $1.to_i)
  when /\[(.+):(.+)\]/
    last_stage, last_state = $1, $2
  end
end

loop do
  sleep 0.1 while file.eof?
  report.call(file.readline)
end
