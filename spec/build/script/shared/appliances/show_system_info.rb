shared_examples_for 'show system info' do
  let(:sexp) { sexp_find(subject, [:fold, 'system_info']) }

  let(:echo_notice)   { [:echo, "Build system information", ansi: :yellow] }
  let(:echo_language) { [:echo, /Build script language/] }
  let(:path)          { '/usr/share/travis/system_info' }
  let(:system_info)   { [:cmd, "cat #{path}"] }

  it 'displays message' do
    expect(sexp).to include_sexp echo_notice
  end

  it 'displays the build script language' do
    expect(sexp).to include_sexp echo_language
  end

  it 'runs command if the system info file exists' do
    branch = sexp_find(sexp, [:if, "-f #{path}"], [:then])
    expect(branch).to include_sexp system_info
  end
end
