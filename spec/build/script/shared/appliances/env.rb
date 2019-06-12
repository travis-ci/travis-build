shared_examples_for 'a script with travis env vars sexp' do
  it 'sets TRAVIS_* env vars', focus: true do
    data[:config][:env].delete_if { |var| var =~ /SECURE / }

    should include_sexp [:export, ['TRAVIS_PULL_REQUEST',    'false']]
    should include_sexp [:export, ['TRAVIS_SECURE_ENV_VARS', 'false']]
    should include_sexp [:export, ['TRAVIS_BUILD_ID',        '1']]
    should include_sexp [:export, ['TRAVIS_BUILD_NUMBER',    '1']]
    should include_sexp [:export, ['TRAVIS_JOB_ID',          '1']]
    should include_sexp [:export, ['TRAVIS_JOB_NUMBER',      '1.1']]
    should include_sexp [:export, ['TRAVIS_BRANCH',          'master']]
    should include_sexp [:export, ['TRAVIS_COMMIT',          data[:job][:commit]]]
    should include_sexp [:export, ['TRAVIS_COMMIT_MESSAGE',  '$(test -d .git && git log --format=%B -n 1 | head -c 32768)']]
    should include_sexp [:export, ['TRAVIS_COMMIT_RANGE',    data[:job][:commit_range]]]
    should include_sexp [:export, ['TRAVIS_REPO_SLUG',       data[:repository][:slug]]]
    should include_sexp [:export, ['TRAVIS_LANGUAGE',        data[:config][:language].to_s]]
    should include_sexp [:export, ['TRAVIS_SUDO',            'true']]

    unless described_class == Travis::Build::Script::Go
      should include_sexp [:export, ['TRAVIS_BUILD_DIR', "#{Travis::Build::BUILD_DIR}/#{data[:repository][:slug]}"]]
    end
  end

  it 'sets TRAVIS_PULL_REQUEST to the given number when running a pull_request' do
    data[:job][:pull_request] = 1
    data[:job][:secure_env_enabled] = false
    should include_sexp [:export, ['TRAVIS_PULL_REQUEST', '1']]
  end

  it 'sets both global and regular env vars' do
    data[:config][:env] = ['FOO=foo', 'BAR=bar']
    data[:config][:global_env] = ['BAZ=baz', 'QUX=qux']

    should include_sexp [:export, ['FOO', 'foo'], echo: true]
    should include_sexp [:export, ['BAR', 'bar'], echo: true]
    should include_sexp [:export, ['BAZ', 'baz'], echo: true]
    should include_sexp [:export, ['QUX', 'qux'], echo: true]

    store_example(name: 'env vars') if data[:config][:language] == :ruby
  end

  it 'sets matrix env vars with higher priority (ie. after global env vars)' do
    data[:config][:env] = ['FOO=foo']
    data[:config][:global_env] = ['FOO=bar']
    should include_sexp [:export, ['FOO', 'foo'], echo: true]
  end

  it 'sets environment variables from settings' do
    data[:config][:env] = nil
    data[:config][:global_env] = nil
    data[:env_vars] = ['name' => 'SETTINGS_VAR', 'value' => 'value', 'public' => false]

    should include_sexp [:export, ['SETTINGS_VAR', 'value'], echo: true, secure: true]
    should include_sexp [:echo, 'Setting environment variables from repository settings', ansi: :yellow]
    should_not include_sexp [:echo, 'Setting environment variables from .travis.yml', ansi: :yellow]
    store_example(name: 'secure settings env var') if data[:config][:language] == :ruby
  end

  it 'sets environment variables from config' do
    data[:config][:global_env] = 'SECURE CONFIG_VAR=value'
    should include_sexp [:export, ['CONFIG_VAR', 'value'], echo: true, secure: true]
    should_not include_sexp [:echo, 'Setting environment variables from repository settings', ansi: :yellow]
    should include_sexp [:echo, 'Setting environment variables from .travis.yml', ansi: :yellow]
    store_example(name: 'secure config env var') if data[:config][:language] == :ruby
  end
end

shared_examples_for 'a script with env vars sexp' do
  it 'sets TRAVIS_SECURE_ENV_VARS to true when using secure env vars' do
    data[:config][env_type] = 'SECURE BAR=bar'
    should include_sexp [:export, ['TRAVIS_SECURE_ENV_VARS', 'true']]
  end

  it 'sets a given :env var' do
    data[:config][env_type] = 'FOO=foo'
    should include_sexp [:export, ['FOO', 'foo'], echo: true]
  end

  it 'sets a given :env var even if empty' do
    data[:config][env_type] = 'SOMETHING_EMPTY=""'
    should include_sexp [:export, ['SOMETHING_EMPTY', '""'], echo: true]
  end

  # TODO what does this add to the tests?
  it 'sets the exact value of a given :env var' do
    data[:config][env_type] = 'BAR=foolish'
    should include_sexp [:export, ['BAR', 'foolish'], echo: true]
  end

  it 'allows setting an env var to another env var' do
    data[:config][env_type] = 'BRANCH=$TRAVIS_BRANCH'
    should include_sexp [:export, ['BRANCH', '$TRAVIS_BRANCH'], echo: true]
  end

  # TODO this is wrong. it only sets UNQUOTED=first
  # it 'sets the exact value of a given :env var, even if definition is unquoted' do
  #   data[:config][env_type] = 'UNQUOTED=first second third ... OTHER=ok'
  #   should include_sexp [:export, 'UNQUOTED', first second third', echo: true
  #   should include_sexp [:export, 'OTHER', ok', echo: true
  # end

  it 'evaluates and sets the exact values of given :env vars, when their definition is encolsed within single or double quotes' do
    data[:config][env_type] = 'SINGLE_QUOTED=\'foo+bar (are) on a boat!\' DOUBLE_QUOTED="$SINGLE_QUOTED"'
    should include_sexp [:export, ['SINGLE_QUOTED', "'foo+bar (are) on a boat!'"], echo: true]
    should include_sexp [:export, ['DOUBLE_QUOTED', '"$SINGLE_QUOTED"'], echo: true ]
  end

  it 'sets multiple :env vars (space separated)' do
    data[:config][env_type] = 'FOO=foo BAR=bar'
    should include_sexp [:export, ['FOO', 'foo'], echo: true]
    should include_sexp [:export, ['BAR', 'bar'], echo: true]
  end

  it 'sets multiple :env vars (array)' do
    data[:config][env_type] = ['FOO=foo', 'BAR=bar']
    should include_sexp [:export, ['FOO', 'foo'], echo: true]
    should include_sexp [:export, ['BAR', 'bar'], echo: true]
  end

  it 'sets a given secure :env var and passes the :secure option' do
    data[:config][env_type] = 'SECURE BAR=bar'
    should include_sexp [:export, ['BAR', 'bar'], echo: true, secure: true]
  end

  it 'does not set secure :env vars if they are disabled' do
    data[:job][:secure_env_enabled] = false
    data[:config][env_type] = 'SECURE BAR=bar'
    should_not include_sexp [:export, ['BAR', 'bar'], echo: true]
  end
end
