shared_examples_for 'paranoid mode on/off' do
  let(:remove_sudo) { %(sudo -n sh -c "sed -e 's/^%.*//' -i.bak /etc/sudoers && rm -f /etc/sudoers.d/travis && find / -perm -4000 -exec chmod a-s {} \\; 2>/dev/null") }

  it 'does not remove access to sudo by default' do
    should_not include_sexp [:cmd, remove_sudo]
  end

  it 'removes access to sudo if enabled in the config' do
    data[:paranoid] = true
    should include_sexp [:cmd, remove_sudo]
    store_example 'disable sudo' if data[:config][:language] == :ruby
  end
end
