shared_examples_for 'paranoid mode on/off' do
  let(:remove_suid) { %r(find / \\\( -perm -4000 -o -perm -2000 \\\) -a ! -name sudo -exec chmod a-s \{\} \\;) }

  it 'does not remove access to sudo by default' do
    should_not include_sexp [:cmd, remove_suid]
  end

  it 'removes access to sudo if enabled in the config' do
    data[:paranoid] = true
    should include_sexp [:cmd, remove_suid]
    store_example 'disable sudo' if data[:config][:language] == :ruby
  end
end
