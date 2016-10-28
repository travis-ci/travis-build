describe 'header.sh', integration: true do
  let(:top) { Pathname.new(ENV.fetch('TOP')) }
  let(:header_sh) { top.join('./lib/travis/build/templates/header.sh').read }
  let(:build_dir) { Dir.mktmpdir(%w(travis-build header-spec)) }

  after :each do
    FileUtils.rm_rf(build_dir)
  end

  let :header_erb_context do
    Struct.new(:header_sh, :build_dir) do
      def render
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
          header_sh, build_dir
        ).render + bash_body,
        err: [:child, :out]
      ]
    ).read
  end

  it 'requires build_dir to render' do
    expect { ERB.new(header_sh).result }.to raise_error(NameError)
  end

  it 'can render' do
    expect(header_erb_context.new(header_sh, build_dir).render).to_not be_empty
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
end
