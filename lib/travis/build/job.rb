require 'hashr'

module Travis
  class Build
    module Job
      autoload :Test,      'travis/build/job/test'
    end
  end
end
