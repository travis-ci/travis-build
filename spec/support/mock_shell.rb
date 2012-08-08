# TODO : merge this with Mocks::Shell
class MockShell
  attr_accessor :echo

  def initialize(echo)
    @echo = echo
  end

  def echo(line, opts)
    @echo << line
  end

  def chdir(*);        true; end
  def export_line(*);  true; end
  def execute(*);      true; end
  def file_exists?(*); true; end
  def cmd(*);          '~/builds' end
end