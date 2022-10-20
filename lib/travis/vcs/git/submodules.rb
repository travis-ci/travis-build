require 'shellwords'

module Travis
  module Vcs
    class Git < Base
      class Submodules < Struct.new(:sh, :data)
        def apply
          sh.if '-f .gitmodules' do
            sh.fold 'git.submodule' do
              sh.file '~/.ssh/config', "Host github.com\n\tStrictHostKeyChecking no\n", append: true
              sh.cmd "git submodule update --init --recursive #{update_args}".strip, assert: true, retry: true
            end
          end
        end

        private

          def update_args
            "--depth=#{depth}" if config[:git].key?(:submodules_depth)
          end

          def depth
            config[:git][:submodules_depth].to_s.shellescape
          end

          def config
            data.config
          end
      end
    end
  end
end
