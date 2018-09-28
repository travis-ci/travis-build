require 'shellwords'

describe 'travis_retry', integration: true do
  let(:container_name) { "travis_retry_#{rand(1000..1999)}" }
  let(:bash_dir) { File.expand_path('../../../lib/travis/build/bash', __dir__) }

  def run_script(command, out: nil, err: nil)
    out ||= Tempfile.new('travis_retry')
    err ||= Tempfile.new('travis_retry')

    script = "source /tmp/tbb/travis_retry.bash; #{command}"

    truth = system(%W[
      docker run
        --rm
        --name=#{container_name}
        -v #{bash_dir}:/tmp/tbb bash:4
        bash -c
      ].join(' ') + ' ' + Shellwords.escape(script),
      out: out.fileno, err: err.fileno
    )

    [out, err].each do |stream|
      stream.rewind if stream.respond_to?(:rewind)
    end

    {
      exitstatus: $?.exitstatus,
      truth: truth,
      out: out,
      err: err
    }
  end

  it 'is valid bash' do
    expect(run_script('')[:truth]).to be true
  end

  it 'returns immediately on success' do
    expect(
      run_script('travis_retry echo whatebber')[:truth]
    ).to be true
  end

  it 'reports retries' do
    expect(
      run_script(
        'travis_retry cat /non/existent/file',
      )[:err].read
    ).to include('Retrying, ')
  end

  it 'reports failure after 3 attempts' do
    expect(
      run_script(
        'travis_retry cat /non/existent/file',
      )[:err].read
    ).to include('failed 3 times.')
  end

  it 'returns the exit code of the process that is retried' do
    expect(
      run_script(
        'travis_retry some-nonexistent-command'
      )[:exitstatus]
    ).to eq 127
  end
end
