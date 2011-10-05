module Travis
  module Build
    autoload :Assertions, 'travis/build/assertions'
    autoload :Connection, 'travis/build/connection'
    autoload :Job,        'travis/build/job'
    autoload :Shell,      'travis/build/shell'
  end
end
