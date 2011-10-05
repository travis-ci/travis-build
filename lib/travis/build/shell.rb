module Travis
  module Build
    class Shell
      autoload :Session, 'travis/build/shell/session'

      attr_reader :session

      def initialize(session)
        @session = session
      end

      def export(name, value, options = {})
        session.execute("export #{name}=#{value}", options) if name
      end

      def chdir(dir)
        session.execute("mkdir -p #{dir}; cd #{dir}", :echo => false)
      end

      def cwd
        session.evaluate('pwd').strip
      end

      def file_exists?(filename)
        session.execute("test -f #{filename}", :echo => false)
      end

      def evaluate(*args)
        session.evaluate(*args)
      end

      def execute(*args)
        session.execute(*args)
      end
    end
  end
end
