require 'shellwords'
require 'travis/vcs/svn/netrc'

module Travis
  module Vcs
    class Svn < Base
      class Clone < Struct.new(:sh, :data)
        def apply
          sh.fold 'svn.checkout' do
            clone
            sh.cd repository_name
            checkout
          end
          sh.newline
        end

        private
          DEFAULT_TRACE_COMMAND = ''

          def repo_slug
            data.repository[:slug].to_s
          end

          def source_url
            if assembla?
              return "svn+ssh://#{data.repository[:source_host]}" unless data.repository[:source_host].start_with?('svn+ssh://')

              return data.repository[:source_host]
            end

            data.repository[:source_url]
          end

          def source_host
            data.repository[:source_host]
          end

          def assembla?
            @assembla ||= source_host.include? 'assembla'
          end

          def owner_login
            repo_slug.split('/').first
          end

          def trace_command
            DEFAULT_TRACE_COMMAND
          end

          def clone
            sh.cmd "svn co #{source_url}#{clone_args} #{repository_name}", assert: false, retry: true
          end

          def checkout
            sh.cmd "svn update -r #{checkout_ref}", timing: false
          end

          def checkout_ref
            ref = if data.tag
                    tag
                  else
                    data.commit
                  end
            ref = ref.split('@')[1] if ref.include?('@')

            ref
          end

          def clone_args
            args = ""
            if branch && branch == 'trunk'
              args << "/#{branch}"
            else
              args << "/branches/#{branch}" if branch
            end
            args
          end

          def host
            URI(source_host)&.host
          end

          def repository_name
            repo_slug&.split('/').last
          end

          def branch
            data.branch.shellescape if data.branch
          end

          def tag
            data.tag.shellescape if data.tag
          end

          def user
            data[:sender_login]
          end

          def config
            data.config
          end
      end
    end
  end
end
