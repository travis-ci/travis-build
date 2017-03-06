require 'json'
require 'faraday'
require 'fileutils'
require 'logger'

def logger
  @logger ||= Logger.new STDOUT
end

def files
  @files ||= []
end

task :default => [:update_static_files]

def fetch_githubusercontent_file(from, to = nil)
  conn = Faraday.new('https://raw.githubusercontent.com')
  to = File.basename(from) unless to
  to = "../public/files/" + to

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

def latest_tag_for(repo)
  conn = Faraday.new('https://api.github.com')

  response = conn.get do |req|
    req.url "repos/#{repo}/releases"
  end

  if response.success?
    json_data = JSON.parse(response.body)
    json_data[0]["name"]
  end
end

desc 'update casher'
task :casher do
  fetch_githubusercontent_file 'travis-ci/casher/production/bin/casher'
end

desc 'update nvm.sh'
task :nvm do
  latest_tag = latest_tag_for 'creationix/nvm'
  node_js_rb_path = File.expand_path('../lib/travis/build/script/node_js.rb', __FILE__)

  logger.info "Latest nvm release is #{latest_tag}"
  sed_cmd = %Q(sed -i "s,^\\(.*\\)NVM_VERSION\s*=.*$,\\1NVM_VERSION = #{latest_tag.gsub(/^v/,'')}," #{node_js_rb_path})

  logger.info "Updating #{node_js_rb_path}"
  `#{sed_cmd}`
  fetch_githubusercontent_file "creationix/nvm/#{latest_tag}/nvm.sh"
end

desc 'update sbt'
task :sbt do
  fetch_githubusercontent_file 'paulp/sbt-extras/master/sbt'
end

desc 'update static files'
task :update_static_files => [:casher, :nvm, :sbt] do
end

desc 'add and commit updated static files'
task :commit_static_files => [:update_static_files] do
  logger.info "Adding #{files.join(" ")} to git staging area"
  `git add #{files.join(" ")}`
  logger.info "Creating a commit"
  `git commit -m "Update static files"`
end
