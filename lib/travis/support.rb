module Travis
  autoload :Assertions, 'travis/support/assertions'
  autoload :Logging,    'travis/support/logging'
  autoload :Retryable,  'travis/support/retryable'

  class << self
    def logger
      @logger ||= Logging.configure(Logger.new(STDOUT))
    end

    def logger=(logger)
      @logger = Logging.configure(logger)
    end
  end
end

