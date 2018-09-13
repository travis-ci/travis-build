shared_examples_for 'disables OpenSSH roaming' do
  let(:sexp) { sexp_find(subject, [:if, %("$(sw_vers -productVersion 2>/dev/null | cut -d . -f 2)" -lt 12)]) }

  it 'disables OpenSSH roaming' do
    expect(sexp).to include_sexp [:cmd, 'travis_disable_ssh_roaming']
  end
end
