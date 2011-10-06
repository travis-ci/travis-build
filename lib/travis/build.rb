module Travis
  module Build
    autoload :Assertions, 'travis/build/assertions'
    autoload :Connection, 'travis/build/connection'
    autoload :Commit,     'travis/build/commit'
    autoload :Event,      'travis/build/event'
    autoload :Factory,    'travis/build/factory'
    autoload :Job,        'travis/build/job'
    autoload :Shell,      'travis/build/shell'

    module Repository
      autoload :Github, 'travis/build/repository/github'
    end

    module Scm
      autoload :Git, 'travis/build/scm/git'
    end
  end
end
