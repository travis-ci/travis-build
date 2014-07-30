class MockShell
  include Travis::Build::Shell::Dsl

  def cmd(*args)
    commands_with_args << args
  end
  alias raw cmd

  def commands
    commands_with_args.map(&:first)
  end

  def commands_with_args
    @commands_with_args ||= []
  end

  def if(*)
    yield(self)
  end
end
