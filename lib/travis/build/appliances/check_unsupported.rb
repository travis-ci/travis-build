require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class CheckUnsupported < Base
        def apply
          lang_name = config[:language]
          unless windows_supports?(lang_name)
            sh.if '"$TRAVIS_OS_NAME" = windows' do
              windows_unsupported_msg(lang_name).each do |line|
                sh.echo line, ansi: :yellow
              end
              sh.raw 'travis_terminate 1'
            end
          end
        end

        def apply?
          true
        end

        private

        def windows_supports?(lang)
          Travis::Build.config.windows_langs.include?(lang)
        end

        def windows_unsupported_msg(lang)
          [
            "",
            "The language '#{lang}' is currently unsupported on the Windows Build Environment.",
            "",
            "Let us know if you'd like to see it: https://travis-ci.community/c/environments/windows. Thanks for understanding!",
          ]
        end

      end
    end
  end
end
