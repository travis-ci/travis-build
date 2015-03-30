# vim:filetype=ruby
SimpleCov.start do
  add_filter '/spec/'
  add_filter '/script/'
  add_filter '/examples/'
  add_filter '/play/'
  add_filter '/tmp/'
end if ENV['COVERAGE']
