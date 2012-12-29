module Travis
  module Build
    module Services
      autoload :BuildScript, 'travis/build/services/build_script'

      class << self
        def register
          constants(false).each { |name| const_get(name) }
        end
      end
    end
  end
end
