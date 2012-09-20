PAYLOADS = {
  :configure => {
    'type'       => 'configure',
    'repository' => { 'slug' => 'travis-ci/travis-ci' },
    'job'        => { 'id' => 1, 'commit' => '313f61b', 'config_url' => 'https://raw.github.com/travis-ci/travis-ci/313f61b/.travis.yml' }
  },
  :test => {
    'type'       => 'test',
    'repository' => { 'slug' => 'travis-ci/travis-ci', 'source_url' => 'git://github.com/travis-ci/travis-ci.git' },
    'job'        => { 'id' => 1, 'commit' => '313f61b', 'branch' => 'master' },
    'config'     => { 'rvm' => '1.9.2', 'env' => 'FOO=foo' }
  },
  :pull_request => {
    'type'       => 'test',
    'repository' => { 'slug' => 'travis-ci/travis-ci', 'source_url' => 'git://github.com/travis-ci/travis-ci.git' },
    'job'        => { 'id' => 1, 'commit' => '313f61b', 'ref' => 'refs/pull/118/merge' },
    'config'     => { 'rvm' => '1.9.2', 'env' => 'FOO=foo' }
  }
}
