require 'core_ext/hash/deep_symbolize_keys'

module Travis
  module Build
    autoload :Buffer, 'travis/build/buffer'
    autoload :Config, 'travis/build/config'
    autoload :Script, 'travis/build/script'
    autoload :Shell,  'travis/build/shell'

    HOME_DIR  = '~'
    BUILD_DIR = '~/builds'

    LOGS = {
      build: '~/build.log',
      state: '~/state.log'
    }

    class << self
      def script(config)
        config = config.deep_symbolize_keys
        lang   = (Array(config[:language]).first || 'ruby').downcase.strip
        const  = by_lang(lang)
        const.new(config)
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
