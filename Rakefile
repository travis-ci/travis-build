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

def sc_data
  conn = Faraday.new("https://saucelabs.com")
  response = conn.get('versions.json')

  unless response.success?
    fail "Could not fetch sc metadata"
  end

  JSON.parse(response.body)
end

def write_sauce_connect_template
  require 'erb'

  app_host = ENV.fetch('TRAVIS_BUILD_APP_HOST', '')

  template = File.read(File.expand_path(File.join("..", 'lib', 'travis', 'build', 'addons', 'sauce_connect', 'templates', 'sauce_connect.sh.erb'), __FILE__))

  File.write(File.expand_path(File.join("..", 'lib', 'travis', 'build', 'addons', 'sauce_connect', 'templates', 'sauce_connect.sh'), __FILE__),
    ERB.new(template).result(binding))
end

def fetch_sc(platform)
  require 'digest/sha1'

  ext = platform == 'linux' ? 'tar.gz' : 'zip'

  download_url = URI.parse(sc_data["Sauce Connect"][platform]["download_url"])

  conn = Faraday.new("#{download_url.scheme}://#{download_url.host}")

  logger.info "getting #{download_url.path}"
  response = conn.get(download_url.path)

  dest = File.expand_path(File.join("..", 'public/files', "sc-#{platform}.#{ext}"), __FILE__)

  archive_content = response.body

  expected_checksum = sc_data["Sauce Connect"][platform]["sha1"]
  received_checksum = Digest::SHA1.hexdigest(archive_content)

  unless received_checksum == expected_checksum
    fail "Checksums did not match: expected #{expected_checksum} received #{received_checksum}"
  end

  logger.info "writing to #{dest}"
  File.write(dest, response.body)
  chmod 'a+rx', dest
end

task 'assets:precompile' => %i(clean update_sc update_godep update_static_files ls_public_files)

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

desc 'update tmate'
file 'public/files/tmate-static-linux-amd64.tar.gz' => 'public/files' do
  latest_release = latest_release_for 'tmate-io/tmate'
  logger.info "Latest tmate release is #{latest_release}"
  fetch_githubusercontent_file "tmate-io/tmate/releases/download/#{latest_release}/tmate-#{latest_release}-static-linux-amd64.tar.gz", "github.com", 'tmate-static-linux-amd64.tar.gz'
end

desc 'update rustup'
file 'public/files/rustup-init.sh' => 'public/files' do
  fetch_githubusercontent_file "", "sh.rustup.rs", "rustup-init.sh"
end

desc 'update sauce_connect.sh'
file 'lib/travis/build/addons/sauce_connect/sauce_connect.sh' do
  write_sauce_connect_template
end

desc 'update sc-linux'
file 'public/files/sc-linux.tar.gz' => 'public/files' do
  fetch_sc('linux')
end

desc 'update sc-mac'
file 'public/files/sc-osx.zip' => 'public/files' do
  fetch_sc('osx')
end

desc 'update sc'
multitask update_sc: Rake::FileList[
  'lib/travis/build/addons/sauce_connect/sauce_connect.sh',
  'public/files/sc-linux.tar.gz',
  'public/files/sc-osx.zip'
]

desc 'update godep'
multitask update_godep: Rake::FileList[
  'public/files/godep_darwin_amd64',
  'public/files/godep_linux_amd64',
]

desc 'update static files'
multitask update_static_files: Rake::FileList[
  'lib/travis/build/addons/sauce_connect/sauce_connect.sh',
  'public/files/sc-linux.tar.gz',
  'public/files/sc-osx.zip',
  'public/files/godep_darwin_amd64',
  'public/files/godep_linux_amd64',
  'public/files/casher',
  'public/files/gimme',
  'public/files/nvm.sh',
  'public/files/sbt',
  'public/files/tmate-static-linux-amd64.tar.gz',
  'public/files/rustup-init.sh'
]

desc "show contents in public/files"
task 'ls_public_files' do
  logger.info `ls -l public/files`
end
