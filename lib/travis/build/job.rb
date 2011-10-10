require 'hashr'

module Travis
  class Build
    module Job
      autoload :Configure, 'travis/build/job/configure'
      autoload :Test,      'travis/build/job/test'
    end
  end
end
