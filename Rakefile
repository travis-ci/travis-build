require 'json'
require 'faraday'
require 'fileutils'
require 'logger'
require 'rubygems'

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
  task :default => [:update_static_files, :spec]
rescue LoadError
  task :default => [:update_static_files]
end

def logger
  @logger ||= Logger.new STDOUT
end


task 'assets:precompile' => :update_static_files

def version_for(version_str)
  Gem::Version.new version_str.match(/\d+(\.\d+)*/)[0]
end

def fetch_githubusercontent_file(from, to = nil)
  conn = Faraday.new('https://raw.githubusercontent.com')
  public_files_dir = "public/files"
  to = File.basename(from) unless to
  to = File.join("..", public_files_dir, to)

  FileUtils.mkdir_p public_files_dir

  response = conn.get do |req|
    logger.info "Fetching #{conn.url_prefix.to_s}#{from}"
    req.url from
  end

  dest = File.expand_path(to, __FILE__)

  if response.success?
    logger.info "Writing to #{dest}"
    File.write(dest, response.body)
    logger.info "Setting mode 'a+rx' on #{dest}"
    FileUtils.chmod "a+rx", dest
  else
    fail "Could not fetch #{from}"
  end
end

def latest_release_for(repo)
  conn = Faraday.new('https://api.github.com')

  response = conn.get do |req|
    releases_url = "repos/#{repo}/releases"
    logger.info "Fetching releases from #{conn.url_prefix.to_s}#{releases_url}"
    req.url releases_url
    oauth_token = ENV['GITHUB_OAUTH_TOKEN']
    if oauth_token
      req.headers['Authorization'] = "token #{oauth_token}"
    end
  end

  if response.success?
    json_data = JSON.parse(response.body)
    fail "No releases found for #{repo}" if json_data.empty?
    json_data.sort { |a,b| version_for(a["name"]) <=> version_for(b["name"]) }.last["name"]
  else
    fail "Could not find releases for #{repo}"
  end
end

desc 'update casher'
task :casher do
  fetch_githubusercontent_file 'travis-ci/casher/production/bin/casher'
end

desc 'update gimme'
task :gimme do
  latest_release = latest_release_for 'travis-ci/gimme'
  logger.info "Latest gimme release is #{latest_release}"
  fetch_githubusercontent_file "travis-ci/gimme/#{latest_release}/gimme"
end

desc 'update nvm.sh'
task :nvm do
  latest_release = latest_release_for 'creationix/nvm'
  logger.info "Latest nvm release is #{latest_release}"
  fetch_githubusercontent_file "creationix/nvm/#{latest_release}/nvm.sh"
  fetch_githubusercontent_file "creationix/nvm/#{latest_release}/nvm-exec"
end

desc 'update sbt'
task :sbt do
  fetch_githubusercontent_file 'paulp/sbt-extras/master/sbt'
end

desc 'update static files'
task :update_static_files => [:casher, :gimme, :nvm, :sbt]
