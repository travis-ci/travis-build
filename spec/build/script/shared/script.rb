shared_examples_for 'compiled script' do
  include SpecHelpers::Shell

  let(:code) { [] }
  let(:cmds) { [] }

  subject { Travis::Build.script(data).compile }

  # it 'output' do
  #   puts subject
  # end

  it 'can be compiled' do
    expect { subject }.to_not raise_error
  end

  it 'includes the expected shell code' do
    code.each do |code|
      should include code
    end
  end

  it 'includes the expected travis_cmds' do
    cmds.each do |cmd|
      should include_shell cmd
    end
  end
end

shared_examples_for 'a build script sexp' do
  it_behaves_like 'a script with travis env vars sexp'
  it_behaves_like 'a script with env vars sexp' do
    let(:env_type) { 'env' }
  end
  it_behaves_like 'a script with env vars sexp' do
    let(:env_type) { 'global_env' }
  end

  it_behaves_like 'show system info'
  it_behaves_like 'validates config'
  it_behaves_like 'paranoid mode on/off'
  it_behaves_like 'fix ps4'
  it_behaves_like 'setup apt cache'
  it_behaves_like 'fix etc/hosts'
  it_behaves_like 'fix resolve.conf'
  it_behaves_like 'put localhost first in etc/hosts'
  it_behaves_like 'starts services'
  it_behaves_like 'build script stages'

  it 'calls travis_result' do
    should include_sexp [:raw, 'travis_result $?']
  end
end
