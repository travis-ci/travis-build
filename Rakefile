begin
  require 'rspec/core/rake_task'
  require 'parallel_tests/tasks'
  require 'rubocop/rake_task'

  RSpec::Core::RakeTask.new(:spec)
  RuboCop::RakeTask.new
rescue LoadError => e
  warn e
end


$LOAD_PATH.unshift(File.expand_path('../lib', __FILE__))
require 'travis/build/rake_tasks'
include Travis::Build::RakeTasks
