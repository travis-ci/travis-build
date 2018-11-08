shared_examples_for 'uninstalls oclint' do
  it 'runs "brew cask uninstall oclint"' do
    should include_sexp [:cmd, 'brew cask uninstall oclint &>/dev/null']
  end
end
