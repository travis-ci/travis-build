module Travis
  module Build
    module Job
      autoload :Configure, 'travis/build/job/configure'
      autoload :Runner,    'travis/build/job/runner'
      autoload :Test,      'travis/build/job/test'
    end
  end
end
