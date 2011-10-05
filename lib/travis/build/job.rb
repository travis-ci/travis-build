require 'hashr'

module Travis
  module Build
    module Job
      autoload :Configure, 'travis/build/job/configure'
      autoload :Runner,    'travis/build/job/runner'
      autoload :Test,      'travis/build/job/test'

      def self.runner(*args)
        Factory.new(*args).runner
      end
    end
  end
end
