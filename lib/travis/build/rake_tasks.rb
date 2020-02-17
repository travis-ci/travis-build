# frozen_string_literal: true

require 'json'
require 'logger'
require 'pathname'
require 'date'

require 'faraday'
require 'faraday_middleware'
require 'minitar'
require 'rake'
require 'rubygems'
require 'tmpdir'

module Travis
  module Build
    module RakeTasks
      SHELLCHECK_VERSION = 'v0.5.0'
      SHELLCHECK_URL = File.join(
        'https://www.googleapis.com',
        '/download/storage/v1/b/shellcheck/o',
        "shellcheck-#{SHELLCHECK_VERSION}.linux.x86_64.tar.xz?alt=media"
      )
      SHFMT_VERSION = 'v2.5.1'
      SHFMT_URL = File.join(
        'https://github.com',
        "mvdan/sh/releases/download/#{SHFMT_VERSION}",
        "shfmt_#{SHFMT_VERSION}_%<uname>s_%<arch>s"
      )

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
          logger.info "Fetching #{conn.url_prefix}#{from}"
          req.url from
        end

        dest = top + to

        dest.dirname.mkpath
        logger.info "Writing to #{dest}"
        dest.write(response.body)
        logger.info "Setting mode '0o#{mode.to_s(8)}' on #{dest}"
        dest.chmod(mode)
      rescue StandardError => e
        logger.info "Error: #{e.message}"
      end

      def latest_release_for(repo)
        conn = build_faraday_conn(host: 'api.github.com')

        response = conn.get do |req|
          releases_url = "repos/#{repo}/releases"
          logger.info "Fetching releases from #{conn.url_prefix}#{releases_url}"
          req.url releases_url
          oauth_token = ENV.fetch(
            'GITHUB_OAUTH_TOKEN', ENV.fetch('no_scope_token', 'notset')
          )
          if oauth_token && !oauth_token.empty? && oauth_token != 'notset'
            logger.info(
              "Adding 'Authorization' header for api.github.com request"
            )
            req.headers['Authorization'] = "token #{oauth_token}"
          end
        end

        raise "Could not find releases for #{repo}" unless response.success?

        json_data = JSON.parse(response.body)
        raise "No releases found for #{repo}" if json_data.empty?

        json_data.sort! do |a, b|
          semver_cmp(a['tag_name'].sub(/^v/, ''), b['tag_name'].sub(/^v/, ''))
        end
        json_data.last['tag_name']
      end

      def file_update_sc_data
        conn = build_faraday_conn(host: 'saucelabs.com')
        response = conn.get('versions.json')
        raise 'Could not fetch sc metadata' unless response.success?

        dest = top + 'tmp/sc_data.json'
        dest.dirname.mkpath
        dest.write(response.body)
        dest.chmod(0o644)
      end

      def sc_data
        @sc_data ||= JSON.parse(top.join('tmp/sc_data.json').read)
      end

      def file_update_sc(platform)
        require 'digest/sha1'

        sc_config = sc_data['Sauce Connect']

        ext = platform == 'linux' ? 'tar.gz' : 'zip'

        download_url = URI.parse(sc_config[platform]['download_url'])

        conn = build_faraday_conn(
          scheme: download_url.scheme,
          host: download_url.host
        )

        logger.info "getting #{download_url.path}"
        response = conn.get(download_url.path)

        dest = top + "public/files/sc-#{platform}.#{ext}"

        archive_content = response.body

        expected_checksum = sc_config[platform]['sha1']
        received_checksum = Digest::SHA1.hexdigest(archive_content)

        unless received_checksum == expected_checksum
          raise "Checksums did not match: expected #{expected_checksum} " \
                "received #{received_checksum}"
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

        key = "#{fullparts[0]}.#{fullparts[1]}"
        expanded[key] = full_version if alias_major_minor

        expanded
      end

      def build_faraday_conn(scheme: 'https', host: 'null.example.com')
        Faraday.new("#{scheme}://#{host}") do |f|
          f.response :raise_error
          f.use FaradayMiddleware::FollowRedirects
          f.request :retry,
                    max: 4,
                    interval: 3,
                    interval_randomness: 0.25,
                    backoff_factor: 1.5,
                    exceptions: [
                      Errno::ETIMEDOUT,
                      Timeout::Error,
                      Faraday::ClientError
                    ],
                    retry_statuses: 400..600
          f.adapter Faraday.default_adapter
        end
      end

      def logger
        @logger ||= Logger.new($stdout)
      end

      def top
        @top ||= Pathname.new(
          File.expand_path('../../..', __dir__)
        )
      end

      def uname
        @uname ||= case RUBY_PLATFORM
                   when /linux/ then 'linux'
                   when /darwin/ then 'darwin'
                   else RUBY_PLATFORM.split('-').last
                   end
      end

      def arch
        @arch ||= case RUBY_PLATFORM
                  when /x86_64/ then 'amd64'
                  else RUBY_PLATFORM.split('-').first
                  end
      end

      def tmpbin
        top.join('tmp/bin')
      end

      def shfmt?
        ENV['PATH'] = tmpbin_path
        `shfmt -version 2>/dev/null`.strip == SHFMT_VERSION
      end

      def shellcheck?
        ENV['PATH'] = tmpbin_path
        vers = `shellcheck --version 2>/dev/null`.strip
        return false if vers.nil? || vers.strip.empty?

        vers.split(/\n/)
            .find { |s| s.start_with?('version:') }
            .split.last == SHELLCHECK_VERSION.sub(/^v/, '')
      end

      def semver_cmp(vers_a, vers_b)
        Gem::Version.new(vers_a.to_s) <=> Gem::Version.new(vers_b.to_s)
      end

      def task_clean
        rm_rf(top + 'examples')
        rm_rf(top + 'public/files')
        rm_rf(top + 'tmp/sc_data.json')
        rm_rf(top + 'tmp/ghc-versions.html')
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

      def file_update_install_jdk_sh
        fetch_githubusercontent_file 'sormuras/bach/master/install-jdk.sh'
      end

      def file_update_tmate
        latest_release = latest_release_for('tmate-io/tmate')
        logger.info "Latest tmate release is #{latest_release}"
        fetch_githubusercontent_file(
          File.join(
            'tmate-io/tmate/releases/download',
            latest_release,
            "tmate-#{latest_release}-static-linux-amd64.tar.gz"
          ),
          host: 'github.com', to: 'tmate-static-linux-amd64.tar.gz'
        )
      end

      def file_update_rustup
        fetch_githubusercontent_file(
          '', host: 'sh.rustup.rs', to: 'rustup-init.sh'
        )
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
        raw.scan(%r{<a href="[^"]+">(?<version>\d[^<>]+)/</a>}i)
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

      def tmpbin_path
        @tmpbin_path ||= %W[
          #{tmpbin}
          #{ENV['PATH']}
        ].join(':')
      end

      def file_update_sonar_scanner(version: ENV['TRAVIS_BUILD_SONAR_CLOUD_CLI_VERSION'] || '3.0.3.778')
        conn = build_faraday_conn(host: 'repo1.maven.org')
        response = conn.get("/maven2/org/sonarsource/scanner/cli/sonar-scanner-cli/#{version}/sonar-scanner-cli-#{version}.zip")
        raise 'Could not fetch SonarCloud scanner CLI archive' unless response.success?

        dest = top + "public/files/sonar-scanner.zip"
        dest.dirname.mkpath
        dest.write(response.body)
        dest.chmod(0o644)
      end

      extend Rake::DSL
      extend self

      task 'assets:precompile' => %i[
        clean
        update_sc
        update_godep
        update_gpg_public_keys
        update_static_files
        update_version_aliases
        ls_public_files
      ]

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

      desc 'update install-jdk.sh'
      file('public/files/install-jdk.sh') { file_update_install_jdk_sh }

      desc 'update tmate'
      file 'public/files/tmate-static-linux-amd64.tar.gz' do
        file_update_tmate
      end

      desc 'update rustup'
      file('public/files/rustup-init.sh') { file_update_rustup }

      desc 'update raw ghc versions'
      file('tmp/ghc-versions.html') { file_update_raw_ghc_versions }

      desc 'update ghc versions'
      file 'public/version-aliases/ghc.json' => 'tmp/ghc-versions.html' do
        file_update_ghc_versions
      end

      desc 'update sauce connect data'
      file('tmp/sc_data.json') { file_update_sc_data }

      desc 'update sc-linux'
      file 'public/files/sc-linux.tar.gz' => 'tmp/sc_data.json' do
        file_update_sc('linux')
      end

      desc 'update sc-mac'
      file 'public/files/sc-osx.zip' => 'tmp/sc_data.json' do
        file_update_sc('osx')
      end

      desc 'update sc'
      multitask update_sc: Rake::FileList[
        'tmp/sc_data.json',
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
        'public/version-aliases/ghc.json'
      ]

      desc 'update sonar-scanner.zip'
      file 'public/files/sonar-scanner.zip' do
        file_update_sonar_scanner
      end

      desc 'update static files'
      multitask update_static_files: Rake::FileList[
        'tmp/sc_data.json',
        'public/files/casher',
        'public/files/gimme',
        'public/files/godep_darwin_amd64',
        'public/files/godep_linux_amd64',
        'public/files/install-jdk.sh',
        'public/files/nvm-exec',
        'public/files/nvm.sh',
        'public/files/rustup-init.sh',
        'public/files/sbt',
        'public/files/sc-linux.tar.gz',
        'public/files/sc-osx.zip',
        'public/files/sonar-scanner.zip',
        'public/files/tmate-static-linux-amd64.tar.gz',
        'public/version-aliases/ghc.json',
      ]

      desc 'update gpg public keys'
      task :update_gpg_public_keys do
        repo_tarball_url = URI(
          ENV.fetch(
            'TRAVIS_BUILD_APT_SOURCE_SAFELIST_REPO_TARBALL',
            'https://codeload.github.com/travis-ci/apt-source-safelist/tar.gz/master'
          )
        )

        conn = build_faraday_conn(host: repo_tarball_url.hostname)
        response = conn.get(repo_tarball_url)

        dest_dir = Pathname.new(File.join(top, 'public/files/gpg'))
        dest_dir.mkpath
        path_parts = repo_tarball_url.path.split('/').map(&:strip)

        Minitar.unpack(
          Zlib::GzipReader.new(StringIO.new(response.body)),
          File.join(top, 'tmp')
        )

        glob_src = "tmp/#{path_parts[2]}-#{path_parts.last}/keys/*.asc"
        Dir.glob(File.join(top, glob_src)) do |src|
          FileUtils.cp(src, dest_dir, verbose: true)
        end
      end

      desc 'show contents in public/files'
      task 'ls_public_files' do
        Rake::FileList['public/files/*'].each { |f| puts f }
      end

      desc 'run shfmt'
      task shfmt: :ensure_shfmt do
        ENV['PATH'] = tmpbin_path
        sh "shfmt -i 2 -w #{top}/lib/travis/build/bash/*.bash"
        sh "shfmt -i 2 -w $(git grep -lE '^#!.+bash' #{top}/script)"
      end

      desc 'run shellcheck'
      task shellcheck: %i[ensure_shellcheck] do
        ENV['PATH'] = tmpbin_path
        sh "shellcheck -s bash #{top}/lib/travis/build/bash/*.bash"
        sh "shellcheck -s bash $(git grep -lE '^#!.+bash' #{top}/script)"
      end

      desc 'assert there are no changes in the git working copy'
      task :assert_clean do
        Dir.chdir(top) do
          sh 'git diff --exit-code'
          sh 'git diff --cached --exit-code'
        end
      end

      desc 'assert validity of all examples'
      task :assert_examples, [:parallel] do |_t, args|
        ENV['PATH'] = tmpbin_path
        if !args[:parallel].nil?
          sh "parallel_rspec -- --tag example:true -- #{top}/spec"
        else
          sh "rspec --tag example:true #{top}/spec"
        end
      end

      desc 'dump build logs for examples if present'
      task :dump_examples_logs do
        (top + 'tmp/examples-build-logs').glob('*.log') do |log_file|
          logger.info "dumping #{log_file}"
          logger.info "---"
          $stdout.write(
            log_file.read.sub(/.+Network availability confirmed\./m, '')
          )
          logger.info "---"
        end
      end

      task :ensure_shfmt do
        next if shfmt?

        tmpbin.mkpath
        dest = tmpbin.join('shfmt')
        dest.parent.mkpath
        dest.write(
          build_faraday_conn(host: nil).get(
            format(SHFMT_URL, uname: uname, arch: arch)
          ).body
        )
        dest.chmod(0o755)
        ENV['PATH'] = tmpbin_path
        sh 'shfmt -version'
      end

      task :ensure_shellcheck do
        raise 'please `brew install shellcheck`' if uname == 'darwin'
        next if shellcheck?

        tmpbin.mkpath
        tmp_dest = Pathname.new(Dir.tmpdir).join('shellcheck.tar.xz')
        tmp_dest.write(build_faraday_conn(host: nil).get(SHELLCHECK_URL).body)
        tar_opts = %(-C "#{tmpbin}" --strip-components=1 --exclude="*.txt")
        sh %(tar #{tar_opts} -xf "#{tmp_dest}")
        ENV['PATH'] = tmpbin_path
        sh 'shellcheck --version'
      end

      task default: %i[
        rubocop
        spec
        shfmt
        assert_clean
        shellcheck
        assert_examples
      ]
    end
  end
end
