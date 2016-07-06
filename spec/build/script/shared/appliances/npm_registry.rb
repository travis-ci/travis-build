shared_examples_for 'npm registry override' do
  it 'sets the NPM_CONFIG_REGISTRY env var' do
    data[:npm_registry] = 'npm-cache.travisci.net'
    should include_sexp [:export, ['NPM_CONFIG_REGISTRY', 'npm-cache.travisci.net'], echo: true]
  end
end
