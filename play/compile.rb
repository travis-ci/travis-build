#!/usr/bin/env ruby

$: << 'lib'
require 'travis/build'

config = {
  urls: {
    logs:  'http://localhost:3000/jobs/1/logs',
    # state:  'http://localhost:3000/jobs/1/state', # not sure about this ...
  },
  repository: {
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
    rvm: '1.9.3',
    # language: 'c',
    # services: ['redis'],
    # after_success: 'yo dawg',
    # after_failure: 'yo kaputt',
    # after_script: 'travis-artifacts upload shit'
    # jdk: 'jdk-foo'
    # script: 'bundle exec rspec'
  }
}

script = Travis::Build.script(config)
script = script.compile
puts script

