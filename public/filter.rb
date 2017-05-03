require 'pty'

module Filter
  class Scanner
    attr_reader :reader

    def initialize(reader)
      @reader = reader
    end

    def read(&block)
      reader.read(&block)
    end

    def run(io)
      read { |char| io.print char }
    end
  end

  class Runner < Scanner
    def read
      PTY.spawn(reader) do |stdout, stdin, _pid|
        yield stdout.readchar until stdout.eof?
      end
    rescue PTY::ChildExited
    end
  end

  class StringFilter < Scanner
    attr_reader :string

    def initialize(reader, string)
      @string = string
      super(reader)
    end

    def read(&block)
      buffer = ""
      reader.read do |char|
        buffer << char
        if string == buffer
          string.size.times { yield '*' }
          buffer = ""
        elsif !string.start_with?(buffer)
          buffer.each_char(&block)
          buffer = ""
        end
      end
    end
  end
end

if __FILE__ == $0
  unless command = ARGV.shift
    $stderr.puts DATA.read
    exit 1
  end

  runner = Filter::Runner.new(command)

  until ARGV.empty?
    case option = ARGV.shift
    when '-e' then runner = Filter::StringFilter.new(runner, ENV[ARGV.shift].to_s)
    when '-s' then runner = Filter::StringFilter.new(runner, ARGV.shift.to_s)
    else
      $stderr.puts "unknown option", DATA.read
      exit 1
    end
  end

  runner.run($stdout)
  exit $?.exitstatus
end

__END__
Usage: filter.rb COMMAND [OPTIONS]
          -e VAR    filter environment variable named VAR
          -s STR    filter string STR
