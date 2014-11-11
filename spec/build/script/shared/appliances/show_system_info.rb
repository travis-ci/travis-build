shared_examples_for 'show system info' do
  let(:sexp) { sexp_find(subject, [:fold, 'system_info']) }

  let(:echo_notice) { [:echo, "Build System Information", ansi: :yellow] }
  let(:system_info) { [:raw, "test -f /usr/local/system_info/system_info.log && cat /usr/local/system_info/system_info.log || true"] }

  it 'displays message' do
    expect(sexp).to include_sexp echo_notice
  end

  it 'runs command' do
    expect(sexp).to include_sexp system_info
  end
end