require 'json'
require 'faraday'
require 'fileutils'
require 'logger'
require 'rubygems'

def logger
  @logger ||= Logger.new STDOUT
end

def files
  @files ||= []
end

task :default => [:update_static_files]

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
    files << dest
  end
end


def latest_release_for(repo)
  conn = Faraday.new('https://api.github.com')

  response = conn.get do |req|
    releases_url = "repos/#{repo}/releases"
    logger.info "Fetching releases from #{conn.url_prefix.to_s}#{releases_url}"
    req.url releases_url
  end

  if response.success?
    json_data = JSON.parse(response.body)
    fail "No releases found for #{repo}" if json_data.empty?
    logger.info "JSON data: #{json_data}"
    json_data.sort { |a,b| version_for(a["name"]) <=> version_for(b["name"]) }.last["name"]
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
  node_js_rb_path = File.expand_path('../lib/travis/build/script/node_js.rb', __FILE__)

  logger.info "Latest nvm release is #{latest_release}"
  sed_cmd = %Q(sed -i "s,^\\(.*\\)NVM_VERSION\s*=.*$,\\1NVM_VERSION = '#{latest_release.gsub(/^v/,'')}'," #{node_js_rb_path})

  logger.info "Updating #{node_js_rb_path}"
  `#{sed_cmd}`
  fetch_githubusercontent_file "creationix/nvm/#{latest_release}/nvm.sh"
  fetch_githubusercontent_file "creationix/nvm/#{latest_release}/nvm-exec"
end

desc 'update sbt'
task :sbt do
  fetch_githubusercontent_file 'paulp/sbt-extras/master/sbt'
end

desc 'update static files'
task :update_static_files => [:casher, :gimme, :nvm, :sbt] do
end

desc 'add and commit updated static files'
task :commit_static_files => [:update_static_files] do
  logger.info "Adding #{files.join(" ")} to git staging area"
  `git add #{files.join(" ")}`
  logger.info "Creating a commit"
  `git commit -m "Update static files"`
end
