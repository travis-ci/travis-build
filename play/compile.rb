#!/usr/bin/env ruby

$: << 'lib'
require 'travis/build'

config = {
  repository: {
    source_url: 'http://github.com/travis-ci/travis-support.git',
    slug: 'travis-ci/travis-support'
  },
  source: {
    id: 1
  },
  job: {
    commit: 'a214c21',
  },
  rvm: '1.9.3',
  # language: 'c',
  # services: ['redis'],
  # after_success: 'yo dawg',
  # after_failure: 'yo kaputt',
  # after_script: 'travis-artifacts upload shit'
  # jdk: 'jdk-foo'
  # script: 'bundle exec rspec'
}

script = Travis::Build.script(config)
script = script.compile
puts script

