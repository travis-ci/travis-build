shared_examples_for 'a script with env vars' do
  it 'sets TRAVIS_SECURE_ENV_VARS to true when using secure env vars' do
    data['config'][env_type] = 'SECURE BAR=bar'
    should set 'TRAVIS_SECURE_ENV_VARS', 'true'
    store_example 'secure_var' if described_class == Travis::Build::Script::Generic
  end

  it 'sets a given :env var' do
    data['config'][env_type] = 'FOO=foo'
    should set 'FOO', 'foo'
  end

  it 'sets a given :env var even if empty' do
    data['config'][env_type] = 'FOO=""'
    should set 'FOO', ''
  end

  it 'sets the exact value of a given :env var' do
    data['config'][env_type] = 'FOO=foolish'
    should_not set 'FOO', 'foo'
  end

  it 'sets the exact value of a given :env var, even if definition is unquoted' do
    data['config'][env_type] = 'UNQUOTED=first second third ... OTHER=ok'
    should set 'UNQUOTED', 'first'
    should set 'OTHER', 'ok'
  end

  it 'it evaluates and sets the exact values of given :env vars, when their definition is encolsed within single or double quotes' do
    data['config'][env_type] = 'SIMPLE_QUOTED=\'foo+bar (are) on a boat!\' DOUBLE_QUOTED="$SIMPLE_QUOTED"'
    should set 'SIMPLE_QUOTED', 'foo+bar (are) on a boat!'
    should set 'DOUBLE_QUOTED', 'foo+bar (are) on a boat!'
  end

  it 'sets multiple :env vars (space separated)' do
    data['config'][env_type] = 'FOO=foo BAR=bar'
    should set 'FOO', 'foo'
    should set 'BAR', 'bar'
  end

  it 'sets multiple :env vars (array)' do
    data['config'][env_type] = ['FOO=foo', 'BAR=bar']
    should set 'FOO', 'foo'
    should set 'BAR', 'bar'
  end

  it 'sets a given secure :env var' do
    data['config'][env_type] = 'SECURE BAR=bar'
    should set 'BAR', 'bar'
  end

  it 'echoes obfuscated secure env vars' do
    data['config'][env_type] = 'SECURE BAR=bar'
    should echo 'export BAR=[secure]'
  end

  it 'does not set secure :env vars on pull requests' do
    data['job']['pull_request'] = 1
    data['config'][env_type] = 'SECURE BAR=bar'
    should_not set 'BAR', 'bar'
  end

  it 'sets both global and regular env vars' do
    data['config']['env'] = ['FOO=foo', 'BAR=bar']
    data['config']['global_env'] = ['BAZ=baz', 'QUX=qux']
    should set 'FOO', 'foo'
    should set 'BAR', 'bar'
    should set 'BAZ', 'baz'
    should set 'QUX', 'qux'
  end
end
