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
    source_url: 'http://github.com/travis-ci/travis-support.git'
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
    rvm: 'ruby-head',
    # jdk: 'jdk-foo',
    # language: 'c',
    # services: ['redis'],
    # after_success: 'yo dawg',
    # after_failure: 'yo kaputt',
    # after_script: 'travis-artifacts upload shit',
    # script: 'bundle exec rspec'
  },
  timeouts: {
    # git_clone: 300
  },
  env_vars: [
    { name: 'FOO', value: 'foo' }
  ]
}

# require 'yaml'
# data[:config] = YAML.load_file('play/config.yml')

# script = Travis::Build.script(data, logs: { build: false, state: true })
script = Travis::Build.script(data)
script = script.compile
puts script

