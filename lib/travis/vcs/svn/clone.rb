require 'shellwords'
require 'travis/vcs/svn/netrc'

module Travis
  module Vcs
    class Svn < Base
      class Clone < Struct.new(:sh, :data)
        def apply
          sh.fold 'svn.checkout' do
            clone
            sh.cd dir
            checkout
          end
          sh.newline
        end

        private
          DEFAULT_TRACE_COMMAND = ''

          def repo_slug
            data.repository[:slug].to_s
          end

          def owner_login
            repo_slug.split('/').first
          end

          def trace_p4_commands?
            false
          end

          def trace_command
            DEFAULT_TRACE_COMMAND
          end

          def clone
            sh.cmd "svn co #{data.source_url}#{clone_args} #{dir}", assert: false, retry: true
          end

          def checkout
            sh.cmd "svn update -r #{checkout_ref}", timing: false
          end

          def checkout_ref
            return tag if data.tag
            data.commit
          end

          def clone_args
            args = ""
            args << "/branches/#{branch}" if branch
            args << " --quiet" if quiet?
            args
          end

          def autocrlf_key_given?
            config[:svn].key?(:autocrlf)
          end

          def host
            config[:svn].host
          end

          def remote
            config[:svn].remote
          end

          def branch
            data.branch.shellescape if data.branch
          end

          def tag
            data.tag.shellescape if data.tag
          end

          def quiet?
            config[:svn][:quiet]
          end

          def lfs_skip_smudge?
            config[:svn][:lfs_skip_smudge] == true
          end

          def sparse_checkout
            config[:svn][:sparse_checkout]
          end

          def dir
            data.slug
          end

          def port
            data.slug.split('/').first
            '6.tcp.ngrok.io:11707'
          end

          def user
            data[:sender_login]
          end

          def ticket
            data[:build_token]
          end

          def config
            data.config
          end
      end
    end
  end
end
