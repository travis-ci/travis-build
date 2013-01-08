require 'core_ext/hash/deep_symbolize_keys'

module Travis
  module Build
    autoload :Data,     'travis/build/data'
    autoload :Script,   'travis/build/script'
    autoload :Services, 'travis/build/services'
    autoload :Shell,    'travis/build/shell'

    HOME_DIR  = '~'
    BUILD_DIR = '~/build'

    LOGS = {
      # log:   '~/build.log',
      state: '~/state.log'
    }

    class << self
      def self.register(key)
        Travis.services.add(key, self)
      end

      def script(data)
        data  = data.deep_symbolize_keys
        lang  = (Array(data[:language]).first || 'ruby').downcase.strip
        const = by_lang(lang)
        const.new(data)
      end

      def by_lang(lang)
        case lang
        when /^java/i then
          Script::PureJava
        when "c++", "cpp", "cplusplus" then
          Script::Cpp
        else
          name = lang.split('_').map { |w| w.capitalize }.join
          Script.const_get(name, false) rescue Script::Ruby
        end
      end
    end
  end
end
