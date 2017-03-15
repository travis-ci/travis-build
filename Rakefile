require 'json'
require 'faraday'
require 'faraday_middleware'
require 'logger'
require 'rubygems'

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
  task default: %i(update_static_files spec)
rescue LoadError
  task default: :update_static_files
end

def logger
  @logger ||= Logger.new STDOUT
end

def version_for(version_str)
  md = version_str.match(/\d+(\.\d+)*/)
  if md
    Gem::Version.new md[0]
  else
    Gem::Version.new nil
  end
end

def fetch_githubusercontent_file(from, host = 'raw.githubusercontent.com', to = nil)
  conn = Faraday.new("https://#{host}") do |f|
    f.use FaradayMiddleware::FollowRedirects
    f.adapter Faraday.default_adapter
  end

  public_files_dir = "public/files"
  to = File.basename(from) unless to
  to = File.join("..", public_files_dir, to)

  response = conn.get do |req|
    logger.info "Fetching #{conn.url_prefix.to_s}#{from}"
    req.url from
  end

  dest = File.expand_path(to, __FILE__)

  logger.info "Writing to #{dest}"
  File.write(dest, response.body)
  logger.info "Setting mode 'a+rx' on #{dest}"
  chmod "a+rx", dest
rescue Exception => e
  logger.info "Error: #{e.message}"
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
    latest = json_data.sort { |a,b| version_for(a["tag_name"]) <=> version_for(b["tag_name"]) }.last["tag_name"]
  else
    fail "Could not find releases for #{repo}"
  end
end

task 'assets:precompile' => %i(clean update_godep update_static_files ls_public_files)

directory 'public/files'

desc 'clean up static files in public/'
task :clean do
  rm_rf('public/files')
end

desc 'update casher'
file 'public/files/casher' => 'public/files' do
  fetch_githubusercontent_file 'travis-ci/casher/production/bin/casher'
end

desc 'update gimme'
file 'public/files/gimme' => 'public/files' do
  latest_release = latest_release_for 'travis-ci/gimme'
  logger.info "Latest gimme release is #{latest_release}"
  fetch_githubusercontent_file "travis-ci/gimme/#{latest_release}/gimme"
end

desc "update godep for Darwin"
file 'public/files/godep_darwin_amd64' => 'public/files' do
  latest_release = latest_release_for 'tools/godep'
  logger.info "Latest godep release is #{latest_release}"
  fetch_githubusercontent_file "tools/godep/releases/download/#{latest_release}/godep_darwin_amd64", "github.com"
end

desc "update godep for Linux"
file 'public/files/godep_linux_amd64' => 'public/files' do
  latest_release = latest_release_for 'tools/godep'
  logger.info "Latest godep release is #{latest_release}"
  fetch_githubusercontent_file "tools/godep/releases/download/#{latest_release}/godep_linux_amd64", "github.com"
end

desc 'update nvm.sh'
file 'public/files/nvm.sh' => 'public/files' do
  latest_release = latest_release_for 'creationix/nvm'
  logger.info "Latest nvm release is #{latest_release}"
  fetch_githubusercontent_file "creationix/nvm/#{latest_release}/nvm.sh"
  fetch_githubusercontent_file "creationix/nvm/#{latest_release}/nvm-exec"
end

desc 'update sbt'
file 'public/files/sbt' => 'public/files' do
  fetch_githubusercontent_file 'paulp/sbt-extras/master/sbt'
end

desc 'update godep'
multitask update_godep: Rake::FileList[
  'public/files/godep_darwin_amd64',
  'public/files/godep_linux_amd64',
]

desc 'update static files'
multitask update_static_files: Rake::FileList[
  'public/files/casher',
  'public/files/gimme',
  'public/files/nvm.sh',
  'public/files/sbt'
]

desc "show contents in public/files"
task 'ls_public_files' do
  logger.info `ls -l public/files`
end
