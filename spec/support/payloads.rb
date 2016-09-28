PAYLOADS = {
  push: {
    'type' => 'test',
    'config' => {
      'os' => 'linux',
      'env' => ['FOO=foo', 'SECURE BAR=bar']
    },
    'repository' => {
      'github_id' => 42,
      'slug' => 'travis-ci/travis-ci',
      'source_url' => 'git://github.com/travis-ci/travis-ci.git',
      'default_branch' => 'master'
    },
    'build' => {
      'id' => '1',
      'number' => '1',
      'previous_state' => 'failed'
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
  },
  push_debug: {
    'type' => 'test',
    'config' => {
      'os' => 'linux',
      'env' => ['FOO=foo', 'SECURE BAR=bar']
    },
    'repository' => {
      'github_id' => 42,
      'slug' => 'travis-ci/travis-ci',
      'source_url' => 'git://github.com/travis-ci/travis-ci.git',
      'default_branch' => 'master'
    },
    'build' => {
      'id' => '1',
      'number' => '1',
      'previous_state' => 'failed'
    },
    'job' => {
      'id' => '1',
      'number' => '1.1',
      'commit' => '313f61b',
      'branch' => 'master',
      'commit_range' => '313f61b..313f61a',
      'commit_message' => 'the commit message',
      'secure_env_enabled' => true,
      'debug_options' => {
        'stage'           => 'before_install',
        'previous_state' => 'failed',
        'created_by'      => 'svenfuchs',
        'quiet'           => false
      }
    }
  },
  worker_config: {
    'paranoid' => true,
    'skip_resolv_updates' => false,
    'skip_etc_hosts_fix' => false,
    'cache_options' => {
      'type' => 's3', # I have no idea where these settings are merged
      'fetch_timeout' => 20,
      'push_timeout' => 30,
      's3' => { # this is in chef
        'bucket' => 'travis-cache-bucket',
        'access_key_id' => 'access_key_id',
        'secret_access_key' => 'secret_access_key'
      }
    }
  }
}
