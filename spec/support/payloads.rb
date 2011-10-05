PAYLOADS = {
  :configure => {
    'repository' => { 'slug' => 'travis-ci/travis-ci' },
    'build'      => { 'id' => 1, 'commit' => '313f61b' }
  },
  :test => {
    'repository' => { 'slug' => 'travis-ci/travis-ci' },
    'build'      => { 'id' => 1, 'commit' => '313f61b' },
    'config'     => { 'rvm' => '1.9.2' }
  }
}
