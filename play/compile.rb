#!/usr/bin/env ruby

$: << 'lib'
require 'travis/build'

data = {
  urls: {
    log:   'http://localhost:3000/jobs/1/log',
    state: 'http://localhost:3000/jobs/1/state', # not sure about this ...
  },
  repository: {
    slug: 'travis-ci/travis-support',
    installation_id: 1,
    source_url: 'https://github.com/travis-ci/travis-support.git'
  },
  source: {
    id: 1,
    number: 1
  },
  job: {
    id: 1,
    number: '1.1',
    branch: 'master',
    commit: 'a214c21',
    commit_range: 'abcdefg..a214c21',
    pull_request: false
  },
  config: {
    # rvm: 'ruby-head',
    # jdk: 'jdk-foo',
     language: 'generic',
     os: 'windows',
    # services: ['redis'],
    after_success: 'echo "after_success"',
    after_failure: 'echo "after_failure"',
    after_script: 'echo "after_script"',
    # script: 'bundle exec rspec'
    script: 'echo $FOO'
  },
  timeouts: {
    # git_clone: 300
  },
  env_vars: [
    { name: 'FOO', value: 'foo', public: true },
    { name: 'BAR', value: 'bar', public: false }
  ]
}

# require 'yaml'
# data[:config] = YAML.load_file('play/config.yml')

# script = Travis::Build.script(data, logs: { build: false, state: true })
script = Travis::Build.script(data)
script = script.compile
puts script
