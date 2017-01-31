module Travis
  autoload :Build, 'travis/build'

  def config
    ::Travis::Build.config
  end

  module_function :config
end
