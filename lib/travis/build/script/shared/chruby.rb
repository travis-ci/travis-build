module Travis
  module Build
    class Script
      module Chruby
        def setup
          super
          setup_chruby if chruby?
        end

        def announce
          super
          sh.cmd 'chruby --version' if chruby?
        end

        def cache_slug
          super.tap { |slug| slug << "--rvm-" << config[:ruby].to_s if chruby? }
        end

        private

          def chruby?
            !!config[:ruby]
          end

          def setup_chruby
            sh.echo 'BETA: Using chruby to select Ruby version. This is currently a beta feature and may change at any time.', ansi: :yellow
            sh.cmd 'curl -sLo ~/chruby.sh https://gist.githubusercontent.com/sarahhodne/a01cd7367b12a59ee051/raw/chruby.sh', echo: false
            sh.cmd 'source ~/chruby.sh', echo: false
            sh.cmd "chruby #{config[:ruby]}", timing: true
          end
      end
    end
  end
end
