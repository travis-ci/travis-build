require 'digest'

module Travis
  module Vcs
    class Git < Base
      class Netrc < Struct.new(:sh, :data)
        def apply
          log_credential_presence
          sh.echo "Using ${TRAVIS_HOME}/#{netrc_filename} to clone repository."
          sh.raw "echo -e #{Shellwords.escape netrc_content} > ${TRAVIS_HOME}/#{netrc_filename}"
          sh.raw "chmod 0600 ${TRAVIS_HOME}/#{netrc_filename}"
        end

        def delete
          sh.raw "rm -f ${TRAVIS_HOME}/#{netrc_filename}"
        end

        private

          # Diagnostic only. Records whether the git credential we are about to write to the
          # netrc is present or EMPTY — an empty credential is exactly what produces the opaque
          # "remote: Invalid username or token. Password authentication is not supported for Git
          # operations." clone failure. This runs server-side (travis-build logs), NOT in the
          # build script, and NEVER logs the token/password value itself — only its presence and
          # safe context. Wrapped so diagnostics can never break the build.
          def log_credential_presence
            return unless defined?(Travis::Build) && Travis::Build.respond_to?(:logger)

            token   = data.token.to_s
            present = !token.strip.empty?
            details = {
              event:              'git_netrc_write',
              repo_slug:          (data.slug rescue nil),
              source_host:        (data.source_host rescue nil),
              auth:               ((data.installation? rescue false) ? 'installation' : 'oauth'),
              installation_id:    ((data.installation_id rescue nil) if (data.installation? rescue false)),
              job_id:             (data.job[:id] rescue nil),
              credential_present: present,      # presence only — the token value is NEVER logged
              credential_length:  token.length, # 0 == empty == clone fails with "Invalid username or token"
              # Non-reversible fingerprint of the SAME token we are about to write. Compare
              # against the mint-time fingerprint (build/data.rb #log_token_fingerprint): equal
              # => the minted token reached the netrc intact; unequal => in-process corruption.
              credential_sha256:  (present ? Digest::SHA256.hexdigest(token)[0, 16] : nil)
            }
            summary = details.reject { |_, v| v.nil? }.map { |k, v| "#{k}=#{v.inspect}" }.join(' ')

            if present
              Travis::Build.logger.info("[git_netrc] writing git credential -- #{summary}")
            else
              Travis::Build.logger.error(
                "[git_netrc] EMPTY git credential -- clone will fail with 'Invalid username or token' -- #{summary}"
              )
            end
          rescue StandardError => e
            Travis::Build.logger.warn("[git_netrc] failed to log credential presence: #{e.class}: #{e.message}") rescue nil
          end

          def netrc_content
            if data.installation?
              "machine #{data.source_host}\n  login travis-ci\n  password #{data.token}\n"
            else
              "machine #{data.source_host}\n  login #{data.token}\n"
            end
          end

          def netrc_filename
            data.config[:os].to_s.downcase == 'windows' ? '_netrc' : '.netrc'
          end
      end
    end
  end
end
