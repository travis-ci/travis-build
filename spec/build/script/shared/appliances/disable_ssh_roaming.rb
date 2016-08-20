shared_examples_for 'disables OpenSSH roaming' do
  let(:disable_ssh_roaming) { %(echo -e "Host *\n  UseRoaming no\n" | cat - $HOME/.ssh/config > $HOME/.ssh/config.tmp && mv $HOME/.ssh/config.tmp $HOME/.ssh/config) }

  it 'disables OpenSSH roaming' do
    should include_sexp [:cmd, disable_ssh_roaming]
  end
end
