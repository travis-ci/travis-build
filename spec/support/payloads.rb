PAYLOADS = {
  :push => {
    'type' => 'test',
    'config' => {
      'env' => ['FOO=foo', 'SECURE BAR=bar'],
      'before_install' => ['./before_install_1.sh', './before_install_2.sh'],
      'before_script'  => ['./before_script_1.sh',  './before_script_2.sh'],
      'after_script'   => ['./after_script_1.sh',   './after_script_2.sh'],
      'after_success'  => ['./after_success_1.sh',  './after_success_2.sh'],
      'after_failure'  => ['./after_failure_1.sh',  './after_failure_2.sh'],
      'deploy'         => ['./deploy_1.sh',         './deploy_2.sh'],
      'os' => 'linux',
    },
    'repository' => {
      'slug' => 'travis-ci/travis-ci',
      'source_url' => 'git://github.com/travis-ci/travis-ci.git'
    },
    'source' => {
      'id' => 1,
      'number' => 1
    },
    'job' => {
      'id' => 1,
      'number' => '1.1',
      'commit' => '313f61b',
      'branch' => 'master',
      'commit_range' => '313f61b..313f61a',
      'commit_message' => 'the commit message',
      'secure_env_enabled' => true
    }
  }
}
