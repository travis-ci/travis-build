PAYLOADS = {
  :push => {
    'type'       => 'test',
    'config'     => {},
    'repository' => { 'slug' => 'travis-ci/travis-ci', 'source_url' => 'git://github.com/travis-ci/travis-ci.git' },
    'job'        => { 'id' => 1, 'commit' => '313f61b' }
  },
  :pull_request => {
    'type'       => 'test',
    'config'     => { 'env' => 'FOO=foo' },
    'repository' => { 'slug' => 'travis-ci/travis-ci', 'source_url' => 'git://github.com/travis-ci/travis-ci.git' },
    'job'        => { 'id' => 1, 'commit' => '313f61b', 'ref' => 'refs/pull/118/merge' }
  }
}
