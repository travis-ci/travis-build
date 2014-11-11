#!/usr/bin/env ruby

$: << 'lib'
require 'travis/build'

data = {
  urls: {
    log:   'http://localhost:3000/jobs/1/log',
    state: 'http://localhost:3000/jobs/1/state', # not sure about this ...
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
    branch: 'staging',
    commit: 'a214c21',
    commit_range: 'abcdefg..a214c21',
    pull_request: false
  },
  config: {
    rvm: '1.9.3',
    before_deploy: "foo bar",
    addons: {
      deploy: {
        provider: 'heroku',
        on: { rvm: '1.9.3' },
        app: {
          production: 'travis-api-production',
          staging: 'travis-api-staging'
        }
      }
    }
  },
  timeouts: {
    # git_clone: 300
  },
  deploy: [{
    provider: 's3',
    access_key_id: 'YOUR AWS ACCESS KEY',
    secret_access_key: 'YOUR AWS SECRET KEY',
    bucket: 'S3 Bucket',
    skip_cleanup: true,
  }]
}

# require 'yaml'
# data[:config] = YAML.load_file('play/config.yml')

script = Travis::Build.script(data)
script = script.compile
puts script #.split("\n")[-50, 50]

