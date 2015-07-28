module Travis
  module Build
    class Script
      module Chruby
        def setup
          super
          if chruby?
            sh.raw File.read(File.join(File.expand_path('templates', __FILE__.sub('.rb', '')), 'chruby.sh'))
            setup_chruby
          end
        end

        def announce
          super
          sh.cmd 'chruby --version' if chruby?
        end

        private

          def chruby?
            !!config[:ruby]
          end

          def setup_chruby
            sh.echo 'BETA: Using chruby to select Ruby version. This is currently a beta feature and may change at any time.', ansi: :yellow
            sh.cmd "chruby #{config[:ruby]}", timing: true
          end
      end
    end
  end
end
