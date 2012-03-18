PAYLOADS = {
  :configure => {
    'type'       => 'configure',
    'repository' => { 'slug' => 'travis-ci/travis-ci' },
    'build'      => { 'id' => 1, 'commit' => '313f61b', 'config_url' => 'https://raw.github.com/travis-ci/travis-ci/313f61b/.travis.yml' }
  },
  :test => {
    'type'       => 'test',
    'repository' => { 'slug' => 'travis-ci/travis-ci' },
    'build'      => { 'id' => 1, 'commit' => '313f61b' },
    'config'     => { 'rvm' => '1.9.2', 'env' => 'FOO=foo' }
  }
}
