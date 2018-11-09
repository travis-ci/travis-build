shared_examples_for 'paranoid mode on/off' do
  it 'does not remove access to sudo by default' do
    should_not include_sexp [:cmd, 'travis_disable_sudo']
  end

  it 'removes access to sudo if enabled in the config' do
    data[:paranoid] = true
    should include_sexp [:cmd, 'travis_disable_sudo']
    store_example(name: 'disable sudo') if data[:config][:language] == :ruby
  end
end
