require 'pathname'

def tmp_top
  @tmp_top ||= Pathname.new(Dir.mktmpdir)
end

Dir.chdir(tmp_top) do
  require 'travis/build/rake_tasks'
end

describe Travis::Build::RakeTasks do
  subject { described_class }

  def releases_response(*versions)
    [
      200,
      { 'Content-Type' => 'application/json' },
      JSON.dump(
        versions.map { |v| { 'tag_name' => v } }
      )
    ]
  end

  let :request_stubs do
    Faraday::Adapter::Test::Stubs.new do |stub|
      %w[
        creationix/nvm
        tmate-io/tmate
        tools/godep
        travis-ci/gimme
      ].each do |repo_slug|
        stub.get("/repos/#{repo_slug}/releases") do |*|
          releases_response('v1.2.3', 'v1.2.5')
        end
      end

      [
        ['tmate-io/tmate', 'tmate-v1.2.5-static-linux-amd64.tar.gz'],
        ['tools/godep', 'godep_darwin_amd64'],
        ['tools/godep', 'godep_linux_amd64']
      ].each do |repo_slug, file_basename|
        stub.get("/#{repo_slug}/releases/download/v1.2.5/#{file_basename}") do |*|
          [200, { 'Content-Type' => 'application/octet-stream' }, "\xb1"]
        end
      end

      %w[
        /
        /creationix/nvm/v1.2.5/nvm-exec
        /creationix/nvm/v1.2.5/nvm.sh
        /paulp/sbt-extras/master/sbt
        /sc-linux.tar.gz
        /sc-osx.zip
        /travis-ci/casher/production/bin/casher
        /travis-ci/gimme/v1.2.5/gimme
      ].each do |filepath|
        stub.get(filepath) do |*|
          [200, { 'Content-Type' => 'application/octet-stream' }, "\xa1"]
        end
      end

      stub.get('/travis-ci/gimme/master/.testdata/sample-binary-linux') do |*|
        [
          200,
          { 'Content-Type' => 'text/plain' },
          %w[
            #uhm
            1.4.0
            1.2.3
            1.9.1
          ].join("\n")
        ]
      end

      stub.get('/~ghc') do |*|
        [
          200,
          { 'Content-Type' => 'text/html' },
          <<-EOF.gsub(/^\s+> ?/, '')
            > <html>
            >   <head><title>wat</title></head>
            >   <body>
            >     <a href="uh">1.2.5/</a>
            >     <a href="uh">9.1.9/</a>
            >     <a href="uh">1.2.3/</a>
            >   </body>
            > </html>
          EOF
        ]
      end

      stub.get('/versions.json') do |*|
        [
          200,
          { 'Content-Type' => 'application/json' },
          JSON.dump(
            'Sauce Connect' => {
              'linux' => {
                'download_url' => 'http://sc.example.com/sc-linux.tar.gz',
                'sha1' => Digest::SHA1.hexdigest("\xa1")
              },
              'osx' => {
                'download_url' => 'http://sc.example.com/sc-osx.zip',
                'sha1' => Digest::SHA1.hexdigest("\xa1")
              }
            }
          )
        ]
      end
    end
  end

  let :conn do
    Faraday.new do |builder|
      builder.adapter :test, request_stubs
    end
  end

  before :all do
    FileUtils.mkdir_p(tmp_top)
  end

  before :each do
    subject.logger.level = Logger::WARN
    subject.stubs(:build_faraday_conn).returns(conn)
    subject.stubs(:top).returns(tmp_top)
    Rake::FileUtilsExt.verbose(false)
    FileUtils.rm_rf(tmp_top.join('*'))
    Dir.chdir(tmp_top)
    tmp_top.mkpath
  end

  after :all do
    Dir.chdir(File.expand_path('../../../', __FILE__))
    FileUtils.rm_rf(tmp_top)
  end

  %w[
    clean
    ls_public_files
    update_godep
    update_sc
    update_static_files
    update_version_aliases
  ].each do |task_name|
    it "defines task #{task_name.inspect}" do
      expect(Rake.application.tasks.map(&:name)).to include(task_name)
    end
  end

  it 'can clean up static files in public/' do
    files = tmp_top + 'public/files'
    files.mkpath
    thing = files + 'thing'
    thing.write('wat')
    Rake::Task[:clean].reenable
    Rake::Task[:clean].invoke
    expect(thing).to_not be_exist
  end

  it 'can clean up intermediate ghc version file' do
    tmp = tmp_top + 'tmp'
    tmp.mkpath
    ghc_versions = tmp + 'ghc-versions.html'
    ghc_versions.write('wat')
    Rake::Task[:clean].reenable
    Rake::Task[:clean].invoke
    expect(ghc_versions).to_not be_exist
  end

  %w[
    public/files/casher
    public/files/gimme
    public/files/godep_darwin_amd64
    public/files/godep_linux_amd64
    public/files/nvm.sh
    public/files/rustup-init.sh
    public/files/sbt
    public/files/sc-linux.tar.gz
    public/files/sc-osx.zip
    public/files/tmate-static-linux-amd64.tar.gz
    public/version-aliases/ghc.json
  ].each do |filename|
    it "can fetch #{filename}" do
      %w[
        tmp/ghc-versions.html
      ].each { |t| Rake::Task[t].reenable }

      Rake::Task[filename].reenable
      Rake::Task[filename].invoke
      expect(tmp_top + filename).to be_exist
    end
  end

  it 'expands available ghc versions into aliases' do
    subject.file_update_raw_ghc_versions
    subject.file_update_ghc_versions
    aliases = JSON.parse(
      (tmp_top + 'public/version-aliases/ghc.json').read
    )
    expect(aliases).to eq(
      '1' => '1.2.5',
      '1.2' => '1.2.5',
      '1.2.3' => '1.2.3',
      '1.2.5' => '1.2.5',
      '1.2.x' => '1.2.5',
      '1.x' => '1.2.5',
      '1.x.x' => '1.2.5',
      '9' => '9.1.9',
      '9.1' => '9.1.9',
      '9.1.9' => '9.1.9',
      '9.1.x' => '9.1.9',
      '9.x' => '9.1.9',
      '9.x.x' => '9.1.9'
    )
  end
end
