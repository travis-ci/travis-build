def mkdir(dir)
  FileUtils.rm_rf(dir)
  FileUtils.mkdir_p(dir)
end

def compare(dir, lft, rgt)
  Dir["#{lft}/*.sh"].each do |file|
    diff = `diff --ignore-all-space #{file} #{file.sub(lft, rgt)}`
    path = file.sub(lft, dir).sub('.sh', '.diff')
    File.open(path, 'w+') { |f| f.write(diff) }
  end
end

dir = 'tmp/diff'
mkdir dir
compare(dir, 'tmp/master', 'tmp/sf-sexp-2')
