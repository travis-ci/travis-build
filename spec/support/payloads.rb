# frozen_string_literal: true

PAYLOADS = {
  push: {
    'type' => 'test',
    'enterprise' => 'false',
    'prefer_https' => false,
    'host' => 'travis-ci.com',
    'config' => {
      'os' => 'linux',
      'arch' => 'amd64',
      'env' => ['FOO=foo', 'SECURE BAR=bar']
    },
    'repository' => {
      'github_id' => 42,
      'slug' => 'travis-ci/travis-ci',
      'source_host' => 'github.com',
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
      'commit' => '03148a8',
      'branch' => 'master',
      'commit_range' => '03148a8..f9da1fd',
      'commit_message' => 'the commit message',
      'secure_env_enabled' => true
    }
  },
  push_debug: {
    'type' => 'test',
    'enterprise' => 'false',
    'prefer_https' => false,
    'host' => 'travis-ci.com',
    'config' => {
      'os' => 'linux',
      'env' => ['FOO=foo', 'SECURE BAR=bar']
    },
    'repository' => {
      'github_id' => 42,
      'slug' => 'travis-ci/travis-ci',
      'source_host' => 'github.com',
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
      'commit' => '03148a8',
      'branch' => 'master',
      'commit_range' => '03148a8..f9da1fd',
      'commit_message' => 'the commit message',
      'secure_env_enabled' => true,
      'debug_options' => {
        'stage' => 'before_install',
        'previous_state' => 'failed',
        'created_by' => 'svenfuchs',
        'quiet' => false
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
}.freeze

PAYLOAD_LANGUAGE_OVERRIDES = {
  node_js: {
    'repository' => {
      'slug' => 'travis-ci-examples/node_js-example'
    },
    'job' => {
      'commit' => 'baaf146',
      'commit_range' => 'e2c19ee..baaf146'
    }
  },
  ruby: {
    'repository' => {
      'slug' => 'travis-ci-examples/ruby-example'
    },
    'job' => {
      'commit' => '9500504',
      'commit_range' => '961e635..9500504'
    }
  },
  python: {
    'repository' => {
      'slug' => 'travis-ci-examples/python-example'
    },
    'job' => {
      'commit' => '637a1e8',
      'commit_range' => '2777cf8..637a1e8'
    },
    'config' => {
      'script' => 'py.test -v'
    }
  },
  go: {
    'repository' => {
      'slug' => 'travis-ci-examples/go-example'
    },
    'job' => {
      'commit' => '80f94a0',
      'commit_range' => 'cf2a57e..80f94a0'
    }
  }
}
