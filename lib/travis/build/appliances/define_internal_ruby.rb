require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class DefineInternalRuby < Base
        def apply
          export_travis_internal_ruby(rvm_ruby('1.9.3'))

          %w(chruby rbenv).each do |strategy|
            sh.if('-z $TRAVIS_INTERNAL_RUBY') do
              export_travis_internal_ruby(send("#{strategy}_ruby", '1.9.3'))
            end
          end

          %w(rvm chruby rbenv).each do |strategy|
            sh.if('-z $TRAVIS_INTERNAL_RUBY') do
              export_travis_internal_ruby(send("#{strategy}_ruby", '2.1'))
            end
          end

          sh.if('-z $TRAVIS_INTERNAL_RUBY') do
            export_travis_internal_ruby('$(which ruby 2>/dev/null)')
          end

          sh.raw('${TRAVIS_INTERNAL_RUBY:-test} -e "p a: 1" &>/dev/null')

          sh.if('$? -ne 0') do
            sh.echo(
              'No compatible ruby interpreter found to define $TRAVIS_INTERNAL_RUBY',
              ansi: :red
            )
            sh.cmd('unset TRAVIS_INTERNAL_RUBY', echo: false)
          end
        end

        private

        def export_travis_internal_ruby(definition)
          sh.export(
            'TRAVIS_INTERNAL_RUBY', definition,
            echo: false, assert: false
          )
        end

        def rvm_ruby(version)
          %{$(rvm #{version} --fuzzy do which ruby 2>/dev/null)}
        end

        def rbenv_ruby(version)
          %{$(rbenv shell "$(echo $(rbenv versions 2>/dev/null | } \
            %{grep -E '[^\.]#{version}' | sort | tail -1))" 2>/dev/null ;} \
            %{rbenv which ruby 2>/dev/null)}
        end

        def chruby_ruby(version)
          %{$(chruby #{version} 2>/dev/null ; which ruby 2>/dev/null)}
        end
      end
    end
  end
end
