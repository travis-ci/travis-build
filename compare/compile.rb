$: << 'lib'

require 'travis/build'
require 'fileutils'

def payloads
  payloads = File.read('tmp/payloads.rb').split("\n")
  payloads.shift
  payloads.map { |payload| eval(payload.gsub("\r", '')) }
end

def mkdir(dir)
  FileUtils.rm_rf(dir)
  FileUtils.mkdir_p(dir)
end

def path_for(dir, payload)
  lang = payload['config'][:language]
  slug = payload['repository']['slug'].sub('/', '_')
  id   = payload['job']['id']
  "#{dir}/#{['build', lang, slug, 'job', id].join('-')}.sh"
end

def filter(code)
  code.gsub(/^echo\n/m, '') # remove newlines
end

def compile(dir, payload)
  path = path_for(dir, payload)
  code = Travis::Build.script(payload).compile
  code = filter(code)
  File.open(path, 'w+') { |f| f.write(code) } if code
end

dir = "tmp/#{`git rev-parse --abbrev-ref HEAD`.chomp}"
mkdir(dir)
payloads.each do |payload|
  compile(dir, payload)
end
