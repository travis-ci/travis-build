PAYLOADS = {
  :push => {
    'type' => 'test',
    'config' => {
      'os' => 'linux',
      'env' => ['FOO=foo', 'SECURE BAR=bar']
    },
    'repository' => {
      'github_id' => 42,
      'slug' => 'travis-ci/travis-ci',
      'source_url' => 'git://github.com/travis-ci/travis-ci.git'
    },
    'build' => {
      'id' => '1',
      'number' => '1'
    },
    'job' => {
      'id' => '1',
      'number' => '1.1',
      'commit' => '313f61b',
      'branch' => 'master',
      'commit_range' => '313f61b..313f61a',
      'commit_message' => 'the commit message',
      'secure_env_enabled' => true
    }
  }
}
