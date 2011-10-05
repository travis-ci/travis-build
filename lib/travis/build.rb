module Travis
  module Build
    autoload :Assertions, 'travis/build/assertions'
    autoload :Connection, 'travis/build/connection'
    autoload :Commit,     'travis/build/commit'
    autoload :Job,        'travis/build/job'
    autoload :Shell,      'travis/build/shell'

    module Repository
      autoload :Git,      'travis/build/repository/git'
      autoload :Github,   'travis/build/repository/github'
    end
  end
end
