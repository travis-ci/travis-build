module SpecHelpers
  module Logger
    def self.included(const)
      const.module_eval do
        let(:stdout) { io.string }
        let(:io)     { StringIO.new }
        let(:logger) { Travis::Build.logger }
        before       { Travis::Build.logger = Travis::Logger.new(io) }
      end
    end
  end
end
