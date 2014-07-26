#!/usr/bin/env ruby

$: << 'lib'

require 'pp'
require 'travis/build'

data = {
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
    language: 'ruby',
    # git: { strategy: 'tarball' },
    # rvm: 'ruby-head',
    # jdk: 'jdk-foo',
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
  ],
  ssh_key: {
    value: 'ssh-key'
  },
}

pp Travis::Build.script(data).sexp
