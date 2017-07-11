require 'json'
require 'logger'
require 'pathname'

require 'faraday'
require 'faraday_middleware'
require 'rake'
require 'rubygems'

module Travis
  module Build
    module RakeTasks
      def fetch_githubusercontent_file(from, host: 'raw.githubusercontent.com',
                                       to: nil, mode: 0o755)
        conn = build_faraday_conn(host: host)
        to = if to
               Pathname.new(to)
             else
               Pathname.new(from).basename
             end
        to = File.join(top, 'public/files', to) unless to.absolute?

        response = conn.get do |req|
          logger.info "Fetching #{conn.url_prefix.to_s}#{from}"
          req.url from
        end

        dest = top + to

        dest.dirname.mkpath
        logger.info "Writing to #{dest}"
        dest.write(response.body)
        logger.info "Setting mode '0o#{mode.to_s(8)}' on #{dest}"
        dest.chmod(mode)
      rescue Exception => e
        logger.info "Error: #{e.message}"
      end

      def latest_release_for(repo)
        conn = build_faraday_conn(host: 'api.github.com')

        response = conn.get do |req|
          releases_url = "repos/#{repo}/releases"
          logger.info "Fetching releases from #{conn.url_prefix.to_s}#{releases_url}"
          req.url releases_url
          oauth_token = ENV['GITHUB_OAUTH_TOKEN']
          if oauth_token
            req.headers['Authorization'] = "token #{oauth_token}"
          end
        end

        if response.success?
          json_data = JSON.parse(response.body)
          fail "No releases found for #{repo}" if json_data.empty?
          json_data.sort! do |a, b|
            semver_cmp(a['tag_name'].sub(/^v/, ''), b['tag_name'].sub(/^v/, ''))
          end
          json_data.last['tag_name']
        else
          fail "Could not find releases for #{repo}"
        end
      end

      def sc_data
        conn = build_faraday_conn(host: 'saucelabs.com')
        response = conn.get('versions.json')

        fail 'Could not fetch sc metadata' unless response.success?
        JSON.parse(response.body)
      end

      def file_update_sauce_connect
        require 'erb'

        dest = top + 'lib/travis/build/addons/sauce_connect/templates/sauce_connect.sh'
        app_host = ENV.fetch('TRAVIS_BUILD_APP_HOST', '')
        dest.dirname.mkpath
        dest.write(ERB.new((top + "#{dest}.erb").read).result(binding))
        dest.chmod(0o644)
      end

      def file_update_sc(platform)
        require 'digest/sha1'

        ext = platform == 'linux' ? 'tar.gz' : 'zip'

        download_url = URI.parse(sc_data['Sauce Connect'][platform]['download_url'])

        conn = build_faraday_conn(
          scheme: download_url.scheme,
          host: download_url.host
        )

        logger.info "getting #{download_url.path}"
        response = conn.get(download_url.path)

        dest = top + "public/files/sc-#{platform}.#{ext}"

        archive_content = response.body

        expected_checksum = sc_data['Sauce Connect'][platform]['sha1']
        received_checksum = Digest::SHA1.hexdigest(archive_content)

        unless received_checksum == expected_checksum
          fail "Checksums did not match: expected #{expected_checksum} received #{received_checksum}"
        end

        dest.dirname.mkpath
        logger.info "writing to #{dest}"
        dest.write(response.body)
        dest.chmod(0o755)
      end

      def expand_semver_aliases(full_version, alias_major_minor: true)
        fullparts = full_version.split('.')
        major = fullparts.first

        expanded = {
          full_version => full_version,
          major => full_version,
          "#{major}.x" => full_version,
          "#{major}.x.x" => full_version,
          "#{fullparts[0]}.#{fullparts[1]}.x" => full_version
        }

        if alias_major_minor
          expanded.merge!(
            "#{fullparts[0]}.#{fullparts[1]}" => full_version,
          )
        end

        expanded
      end

      def build_faraday_conn(scheme: 'https', host: 'null.example.com')
        Faraday.new("#{scheme}://#{host}") do |f|
          f.response :raise_error
          f.use FaradayMiddleware::FollowRedirects
          f.adapter Faraday.default_adapter
        end
      end

      def logger
        @logger ||= Logger.new($stdout)
      end

      def top
        @top ||= Pathname.new(
          File.expand_path('../../../../', __FILE__)
        )
      end

      def semver_cmp(a, b)
        Gem::Version.new(a.to_s) <=> Gem::Version.new(b.to_s)
      end

      def task_clean
        rm_rf(top + 'public/files')
      end

      def file_update_casher
        fetch_githubusercontent_file 'travis-ci/casher/production/bin/casher'
      end

      def file_update_gimme
        latest_release = latest_release_for('travis-ci/gimme')
        logger.info "Latest gimme release is #{latest_release}"
        fetch_githubusercontent_file "travis-ci/gimme/#{latest_release}/gimme"
      end

      def file_update_godep_for_darwin
        latest_release = latest_release_for('tools/godep')
        logger.info "Latest godep release is #{latest_release}"
        fetch_githubusercontent_file(
          "tools/godep/releases/download/#{latest_release}/godep_darwin_amd64",
          host: 'github.com'
        )
      end

      def file_update_godep_for_linux
        latest_release = latest_release_for('tools/godep')
        logger.info "Latest godep release is #{latest_release}"
        fetch_githubusercontent_file(
          "tools/godep/releases/download/#{latest_release}/godep_linux_amd64",
          host: 'github.com'
        )
      end

      def file_update_nvm
        latest_release = latest_release_for('creationix/nvm')
        logger.info "Latest nvm release is #{latest_release}"
        fetch_githubusercontent_file "creationix/nvm/#{latest_release}/nvm.sh"
      end

      def file_update_nvm_exec
        latest_release = latest_release_for('creationix/nvm')
        logger.info "Latest nvm release is #{latest_release}"
        fetch_githubusercontent_file "creationix/nvm/#{latest_release}/nvm-exec"
      end

      def file_update_sbt
        fetch_githubusercontent_file 'paulp/sbt-extras/master/sbt'
      end

      def file_update_tmate
        latest_release = latest_release_for('tmate-io/tmate')
        logger.info "Latest tmate release is #{latest_release}"
        fetch_githubusercontent_file(
          File.join(
            'tmate-io/tmate/releases/download',
            latest_release,
            "tmate-#{latest_release}-static-linux-amd64.tar.gz",
          ),
          host: 'github.com', to: 'tmate-static-linux-amd64.tar.gz'
        )
      end

      def file_update_rustup
        fetch_githubusercontent_file(
          '', host: 'sh.rustup.rs', to: 'rustup-init.sh'
        )
      end

      def file_update_raw_go_versions
        fetch_githubusercontent_file(
          'travis-ci/gimme/master/.testdata/sample-binary-linux',
          to: top + 'tmp/go-versions-binary-linux',
          mode: 0o644
        )
      end

      def file_update_go_versions
        raw = (top + 'tmp/go-versions-binary-linux').read
                                                    .split(/\n/)
                                                    .reject do |line|
          line.strip.empty? || line.strip.start_with?('#')
        end

        raw.sort!(&method(:semver_cmp))

        out = {}
        raw.each do |full_version|
          out.merge!(
            expand_semver_aliases(full_version, alias_major_minor: false)
          )
        end

        raise StandardError, 'no go versions parsed' if out.empty?

        out.merge!(
          '1.2' => '1.2.2',
          'go1' => 'go1'
        )

        dest = top + 'public/version-aliases/go.json'
        dest.dirname.mkpath
        dest.write(JSON.pretty_generate(out))
        dest.chmod(0o644)
      end

      def file_update_raw_ghc_versions
        fetch_githubusercontent_file(
          '~ghc',
          host: 'downloads.haskell.org',
          to: top + 'tmp/ghc-versions.html',
          mode: 0o644
        )
      end

      def file_update_ghc_versions
        out = {}

        raw = (top + 'tmp/ghc-versions.html').read
        raw.scan(%r[<a href="[^"]+">(?<version>\d[^<>]+)/</a>]i)
           .to_a
           .flatten
           .reject { |v| v =~ /-(rc|latest)/ }
           .sort(&method(:semver_cmp))
           .each do |full_version|
          out.merge!(expand_semver_aliases(full_version))
        end

        raise StandardError, 'no ghc versions parsed' if out.empty?
        dest = top + 'public/version-aliases/ghc.json'
        dest.dirname.mkpath
        dest.write(JSON.pretty_generate(out))
        dest.chmod(0o644)
      end

      extend self
      extend Rake::DSL

      task 'assets:precompile' => %i(
        clean
        update_sc
        update_godep
        update_static_files
        ls_public_files
      )

      desc 'clean up static files in public/'
      task(:clean) { task_clean }

      desc 'update casher'
      file('public/files/casher') { file_update_casher }

      desc 'update gimme'
      file('public/files/gimme') { file_update_gimme }

      desc 'update godep for Darwin'
      file('public/files/godep_darwin_amd64') { file_update_godep_for_darwin }

      desc 'update godep for Linux'
      file('public/files/godep_linux_amd64') { file_update_godep_for_linux }

      desc 'update nvm.sh'
      file('public/files/nvm.sh') { file_update_nvm }

      desc 'update nvm-exec'
      file('public/files/nvm-exec') { file_update_nvm_exec }

      desc 'update sbt'
      file('public/files/sbt') { file_update_sbt }

      desc 'update tmate'
      file 'public/files/tmate-static-linux-amd64.tar.gz' do
        file_update_tmate
      end

      desc 'update rustup'
      file('public/files/rustup-init.sh') { file_update_rustup }

      desc 'update raw go versions'
      file 'tmp/go-versions-binary-linux' do
        file_update_raw_go_versions
      end

      desc 'update go versions'
      file 'public/version-aliases/go.json' => 'tmp/go-versions-binary-linux' do
        file_update_go_versions
      end

      desc 'update raw ghc versions'
      file('tmp/ghc-versions.html') { file_update_raw_ghc_versions }

      desc 'update ghc versions'
      file 'public/version-aliases/ghc.json' => 'tmp/ghc-versions.html' do
        file_update_ghc_versions
      end

      desc 'update sauce_connect.sh'
      file 'lib/travis/build/addons/sauce_connect/sauce_connect.sh' do
        file_update_sauce_connect
      end

      desc 'update sc-linux'
      file 'public/files/sc-linux.tar.gz' do
        file_update_sc('linux')
      end

      desc 'update sc-mac'
      file 'public/files/sc-osx.zip' do
        file_update_sc('osx')
      end

      desc 'update sc'
      multitask update_sc: Rake::FileList[
        'lib/travis/build/addons/sauce_connect/sauce_connect.sh',
        'public/files/sc-linux.tar.gz',
        'public/files/sc-osx.zip'
      ]

      desc 'update godep'
      multitask update_godep: Rake::FileList[
        'public/files/godep_darwin_amd64',
        'public/files/godep_linux_amd64'
      ]

      desc 'update version aliases'
      multitask update_version_aliases: Rake::FileList[
        'public/version-aliases/ghc.json',
        'public/version-aliases/go.json'
      ]

      desc 'update static files'
      multitask update_static_files: Rake::FileList[
        'lib/travis/build/addons/sauce_connect/sauce_connect.sh',
        'public/files/casher',
        'public/files/gimme',
        'public/files/godep_darwin_amd64',
        'public/files/godep_linux_amd64',
        'public/files/nvm-exec',
        'public/files/nvm.sh',
        'public/files/rustup-init.sh',
        'public/files/sbt',
        'public/files/sc-linux.tar.gz',
        'public/files/sc-osx.zip',
        'public/files/tmate-static-linux-amd64.tar.gz'
      ]

      desc 'show contents in public/files'
      task 'ls_public_files' do
        Rake::FileList['public/files/*'].each { |f| puts f }
      end
    end
  end
end
