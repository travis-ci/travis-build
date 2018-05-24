require 'shellwords'

module Filter
  class Scanner < Struct.new(:reader)
    def run(io)
      read { |char| io.print char }
    end
  end

  class Stdin < Scanner
    def read(&block)
      while !$stdin.eof? && char = $stdin.readchar
        block.call char
      end
    end
  end

  class StringFilter < Scanner
    attr_reader :string

    def initialize(reader, string)
      @string = string
      super(reader)
    end

    def read(&block)
      buffer = ''
      reader.read do |char|
        buffer << char
        if string == buffer
          yield '[secure]'
          buffer.clear
        elsif !string.start_with?(buffer)
          buffer.each_char(&block)
          buffer.clear
        end
      end
    end
  end
end

def unescape(str)
  `echo #{str}`.chomp rescue ''
end

if __FILE__ == $0
  secrets = []

  until ARGV.empty?
    case option = ARGV.shift
    when '-e' then secrets << ENV[ARGV.shift].to_s
    when '-s' then secrets << ARGV.shift
    else
      $stderr.puts "unknown option", DATA.read
      exit 1
    end
  end

  secrets = secrets.reject { |s| s.length < 3 }
  secrets = secrets.map { |s| [s, unescape(s)] }.flatten
  secrets = secrets.uniq.sort_by { |s| -s.length }

  filter = secrets.inject(Filter::Stdin.new($stdin)) do |filter, secret|
    Filter::StringFilter.new(filter, secret)
  end

  filter.run($stdout)
end

__END__
Usage: filter.rb [OPTIONS]
          -e VAR filter environment variable named VAR
          -s STR filter string STR
