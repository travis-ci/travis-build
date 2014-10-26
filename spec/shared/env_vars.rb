shared_examples_for 'a script with env vars' do
  it 'sets TRAVIS_SECURE_ENV_VARS to true when using secure env vars' do
    data['config'][env_type] = 'SECURE BAR=bar'
    is_expected.to set 'TRAVIS_SECURE_ENV_VARS', 'true'
    store_example 'secure_var' if described_class == Travis::Build::Script::Generic
  end

  it 'sets a given :env var' do
    data['config'][env_type] = 'FOO=foo'
    is_expected.to travis_cmd 'export FOO=foo', echo: true
  end

  it 'sets a given :env var even if empty' do
    data['config'][env_type] = 'SOMETHING_EMPTY=""'
    is_expected.to travis_cmd 'export SOMETHING_EMPTY=""', echo: true
  end

  it 'sets the exact value of a given :env var' do
    data['config'][env_type] = 'BAR=foolish'
    is_expected.not_to travis_cmd 'export BAR=foo', echo: true
  end

  it 'allows setting an env var to another env var' do
    data['config'][env_type] = 'BRANCH=$TRAVIS_BRANCH'
    is_expected.to travis_cmd 'export BRANCH=$TRAVIS_BRANCH', echo: true
  end

  # TODO this is wrong. it only sets UNQUOTED=first
  # it 'sets the exact value of a given :env var, even if definition is unquoted' do
  #   data['config'][env_type] = 'UNQUOTED=first second third ... OTHER=ok'
  #   is_expected.to travis_cmd 'export UNQUOTED=first second third', echo: true
  #   is_expected.to travis_cmd 'export OTHER=ok', echo: true
  # end

  it 'evaluates and sets the exact values of given :env vars, when their definition is encolsed within single or double quotes' do
    data['config'][env_type] = 'SINGLE_QUOTED=\'foo+bar (are) on a boat!\' DOUBLE_QUOTED="$SINGLE_QUOTED"'
    is_expected.to travis_cmd "export SINGLE_QUOTED='foo+bar (are) on a boat!'", echo: true
    is_expected.to travis_cmd 'export DOUBLE_QUOTED="$SINGLE_QUOTED"', echo: true
  end

  it 'sets multiple :env vars (space separated)' do
    data['config'][env_type] = 'FOO=foo BAR=bar'
    is_expected.to travis_cmd "export FOO=foo", echo: true
    is_expected.to travis_cmd "export BAR=bar", echo: true
  end

  it 'sets multiple :env vars (array)' do
    data['config'][env_type] = ['FOO=foo', 'BAR=bar']
    is_expected.to travis_cmd "export FOO=foo", echo: true
    is_expected.to travis_cmd "export BAR=bar", echo: true
  end

  it 'sets a given secure :env var and obfuscates it' do
    data['config'][env_type] = 'SECURE BAR=bar'
    is_expected.to travis_cmd "export BAR=bar", echo: true, display: 'export BAR=[secure]'
  end

  it 'does not set secure :env vars if they\'re disabled' do
    data['job']['secure_env_enabled'] = false
    data['config'][env_type] = 'SECURE BAR=bar'
    is_expected.not_to travis_cmd "export BAR=bar", echo: true, display: 'export BAR=[secure]'
  end

  it 'sets both global and regular env vars' do
    data['config']['env'] = ['FOO=foo', 'BAR=bar']
    data['config']['global_env'] = ['BAZ=baz', 'QUX=qux']
    is_expected.to travis_cmd "export FOO=foo", echo: true
    is_expected.to travis_cmd "export BAR=bar", echo: true
    is_expected.to travis_cmd "export BAZ=baz", echo: true
    is_expected.to travis_cmd "export QUX=qux", echo: true
  end

  it 'sets matrix env vars with higher priority (ie. after global env vars)' do
    data['config']['env'] = ['FOO=foo']
    data['config']['global_env'] = ['FOO=bar']
    is_expected.to travis_cmd "export FOO=foo", echo: true
  end
end
