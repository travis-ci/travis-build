def checkout(branch)
  puts "Checking out #{branch}"
  system "git checkout #{branch}"
  sleep 1
end

branches = ARGV
branches.each do |branch|
  checkout(branch)
  system 'bundle exec ruby compare/compile.rb'
end

system 'ruby compare/compare.rb'
