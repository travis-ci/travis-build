STDIN.each_line.with_index do |line, ix|
  line = line.inspect.gsub(/^"|"$/, '')
  puts "#{ix} #{line}"
end
