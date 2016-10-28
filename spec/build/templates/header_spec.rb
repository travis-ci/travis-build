describe 'header.sh', integration: true do
  let(:top) { Pathname.new(ENV.fetch('TOP')) }
  let(:header_sh) { top.join('./lib/travis/build/templates/header.sh').read }
  let(:build_dir) { Dir.mktmpdir(%w(travis-build header-spec)) }

  after :each do
    FileUtils.rm_rf(build_dir)
  end

  let :header_erb_context do
    Struct.new(:header_sh, :build_dir, :root, :home) do
      def render
        @root = root
        @home = home
        ERB.new(header_sh).result(binding)
      end
    end
  end

  let :bash_body do
    script = %w(export)
    header_sh.split("\n").grep(/^[a-z][a-z_]+\(\) \{/).each do |func|
      script << "type #{func.match(/^(.+)\(\) \{/)[1]}"
    end
    script.join("\n")
  end

  let :bash_output do
    IO.popen(
      [
        'bash', '-c',
        header_erb_context.new(
          header_sh, build_dir, build_dir, build_dir
        ).render + bash_body,
        err: [:child, :out]
      ]
    ).read
  end

  it 'requires build_dir to render' do
    expect { ERB.new(header_sh).result }.to raise_error(NameError)
  end

  it 'can render' do
    expect(
      header_erb_context.new(
        header_sh, build_dir, build_dir, build_dir
      ).render
    ).to_not be_empty
  end

  %w(
    travis_assert
    travis_cmd
    travis_fold
    travis_internal_ruby
    travis_jigger
    travis_nanoseconds
    travis_result
    travis_retry
    travis_terminate
    travis_time_finish
    travis_time_start
    travis_wait
  ).each do |api_function|
    it "defines #{api_function}" do
      expect(bash_output).to match(/^#{api_function} is a function/)
    end
  end

  describe 'internal ruby selection' do
    let(:rubies) { [] }

    let :bash_body do
      <<-EOF.gsub(/^\s+> ?/, '')
        > rvm() {
        >   cat <<EORVM
        > #{rubies.join("\n")}
        > EORVM
        > }
        >
        > echo $(travis_internal_ruby)
      EOF
    end

    context 'with a typical selection of preinstalled rubies' do
      let :rubies do
        [
          'ruby-1.7.19-p000',
          'ruby-1.8.7-p000',
          'ruby-1.8.7-p000',
          'ruby-1.9.2-p000',
          'ruby-1.9.3-p000',
          'ruby-2.0.0 [ x86_64 ]',
          'ruby-2.1.2 [ x86_64 ]',
          'ruby-2.1.3 [ x86_64 ]',
          'ruby-2.1.4 [ x86_64 ]',
          'ruby-2.1.5 [ x86_64 ]',
          'ruby-2.2.0 [ x86_64 ]',
          'ruby-2.2.5 [ x86_64 ]',
          'ruby-2.3.1 [ x86_64 ]'
        ]
      end

      it 'selects the latest valid version' do
        expect(bash_output.strip).to eq('2.2.5')
      end
    end

    context 'when the most recent version of ruby is 1.9.3' do
      let :rubies do
        [
          'ruby-1.7.19-p000',
          'ruby-1.8.7-p000',
          'ruby-1.8.7-p000',
          'ruby-1.9.2-p000',
          'ruby-1.9.3-p000'
        ]
      end

      it 'selects 1.9.3' do
        expect(bash_output.strip).to eq('1.9.3')
      end
    end

    context 'when the most recent version of ruby is 2.1.10' do
      let :rubies do
        [
          'ruby-1.9.3-p000',
          'ruby-2.0.0 [ x86_64 ]',
          'ruby-2.1.2 [ x86_64 ]',
          'ruby-2.1.3 [ x86_64 ]',
          'ruby-2.1.4 [ x86_64 ]',
          'ruby-2.1.5 [ x86_64 ]',
          'ruby-2.1.10 [ x86_64 ]'
        ]
      end

      it 'selects 2.1.5' do
        expect(bash_output.strip).to eq('2.1.5')
      end
    end
  end
end
