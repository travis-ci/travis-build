shared_examples_for 'a script with env vars' do
  it 'sets TRAVIS_SECURE_ENV_VARS to true when using secure env vars' do
    data['config'][env_type] = 'SECURE BAR=bar'
    is_expected.to set 'TRAVIS_SECURE_ENV_VARS', 'true'
    store_example 'secure_var' if described_class == Travis::Build::Script::Generic
  end

  it 'sets a given :env var' do
    data['config'][env_type] = 'FOO=foo'
    is_expected.to set 'FOO', 'foo'
  end

  it 'sets a given :env var even if empty' do
    data['config'][env_type] = 'SOMETHING_EMPTY=""'
    is_expected.to set 'SOMETHING_EMPTY', ''
  end

  it 'sets the exact value of a given :env var' do
    data['config'][env_type] = 'BAR=foolish'
    is_expected.not_to set 'BAR', 'foo'
  end

  it 'sets the exact value of a given :env var, even if definition is unquoted' do
    data['config'][env_type] = 'UNQUOTED=first second third ... OTHER=ok'
    is_expected.to set 'UNQUOTED', 'first'
    is_expected.to set 'OTHER', 'ok'
  end

  it 'it evaluates and sets the exact values of given :env vars, when their definition is encolsed within single or double quotes' do
    data['config'][env_type] = 'SIMPLE_QUOTED=\'foo+bar (are) on a boat!\' DOUBLE_QUOTED="$SIMPLE_QUOTED"'
    is_expected.to set 'SIMPLE_QUOTED', 'foo+bar (are) on a boat!'
    is_expected.to set 'DOUBLE_QUOTED', 'foo+bar (are) on a boat!'
  end

  it 'sets multiple :env vars (space separated)' do
    data['config'][env_type] = 'FOO=foo BAR=bar'
    is_expected.to set 'FOO', 'foo'
    is_expected.to set 'BAR', 'bar'
  end

  it 'sets multiple :env vars (array)' do
    data['config'][env_type] = ['FOO=foo', 'BAR=bar']
    is_expected.to set 'FOO', 'foo'
    is_expected.to set 'BAR', 'bar'
  end

  it 'sets a given secure :env var' do
    data['config'][env_type] = 'SECURE BAR=bar'
    is_expected.to set 'BAR', 'bar'
  end

  it 'echoes obfuscated secure env vars' do
    data['config'][env_type] = 'SECURE BAR=bar'
    is_expected.to echo 'export BAR=[secure]'
  end

  it 'does not set secure :env vars if they\'re disabled' do
    data['job']['secure_env_enabled'] = false
    data['config'][env_type] = 'SECURE BAR=bar'
    is_expected.not_to set 'BAR', 'bar'
  end

  it 'sets both global and regular env vars' do
    data['config']['env'] = ['FOO=foo', 'BAR=bar']
    data['config']['global_env'] = ['BAZ=baz', 'QUX=qux']
    is_expected.to set 'FOO', 'foo'
    is_expected.to set 'BAR', 'bar'
    is_expected.to set 'BAZ', 'baz'
    is_expected.to set 'QUX', 'qux'
  end

  it 'sets matrix env vars with bigger priority (ie. after global env vars)' do
    data['config']['env'] = ['FOO=foo']
    data['config']['global_env'] = ['FOO=bar']

    is_expected.to set 'FOO', 'foo'
  end
end
