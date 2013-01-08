require 'core_ext/hash/deep_merge'
require 'core_ext/hash/deep_symbolize_keys'
require 'core_ext/object/false'
require 'erb'

module Travis
  module Build
    class Script
      autoload :C,        'travis/build/script/c'
      autoload :Cpp,      'travis/build/script/cpp'
      autoload :Clojure,  'travis/build/script/clojure'
      autoload :Erlang,   'travis/build/script/erlang'
      autoload :Git,      'travis/build/script/git'
      autoload :Go,       'travis/build/script/go'
      autoload :Groovy,   'travis/build/script/groovy'
      autoload :Haskell,  'travis/build/script/haskell'
      autoload :Helpers,  'travis/build/script/helpers'
      autoload :Jdk,      'travis/build/script/jdk'
      autoload :Jvm,      'travis/build/script/jvm'
      autoload :NodeJs,   'travis/build/script/node_js'
      autoload :Perl,     'travis/build/script/perl'
      autoload :Php,      'travis/build/script/php'
      autoload :PureJava, 'travis/build/script/pure_java'
      autoload :Python,   'travis/build/script/python'
      autoload :Ruby,     'travis/build/script/ruby'
      autoload :Scala,    'travis/build/script/scala'
      autoload :Services, 'travis/build/script/services'
      autoload :Stages,   'travis/build/script/stages'

      TEMPLATES_PATH = File.expand_path('../script/templates', __FILE__)

      STAGES = {
        builtin: [:export, :checkout, :setup, :announce],
        custom:  [:before_install, :install, :before_script, :script, :after_result, :after_script]
      }

      include Git, Helpers, Services, Stages

      attr_reader :stack, :data

      def initialize(data)
        @data = Data.new({ config: self.class::DEFAULTS }.deep_merge(data.deep_symbolize_keys))
        @stack = [Shell::Script.new(echo: true)]
      end

      def compile
        # raw template 'report.sh'
        raw template 'header.sh'
        run_stages
        raw template 'footer.sh'
        sh.to_s
      end

      private

        def template(filename)
          ERB.new(File.read(File.expand_path(filename, TEMPLATES_PATH))).result(binding)
        end

        def export
          data.env.each do |key, value|
            set key, value, echo: key.to_s !~ /^TRAVIS_/ # TODO secure stuff?
          end
        end

        def setup
          start_services
        end

        def announce
          # overwrite
        end
    end
  end
end
