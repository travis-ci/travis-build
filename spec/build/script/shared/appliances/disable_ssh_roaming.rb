shared_examples_for 'disables OpenSSH roaming' do
  let(:disable_ssh_roaming) { %(echo -e "Host *\n  UseRoaming no\n" | cat - $HOME/.ssh/config > $HOME/.ssh/config.tmp && mv $HOME/.ssh/config.tmp $HOME/.ssh/config) }
  let(:sexp) { sexp_find(subject, [:if, %("$(sw_vers -productVersion 2>/dev/null | cut -d . -f 2)" -lt 12)]) }

  it 'disables OpenSSH roaming' do
    expect(sexp).to include_sexp [:cmd, disable_ssh_roaming]
  end
end
