begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
  task default: %i(update_static_files spec)
rescue LoadError
  task default: :update_static_files
end

$LOAD_PATH.unshift(File.expand_path('../lib', __FILE__))
require 'travis/build/rake_tasks'
include Travis::Build::RakeTasks
