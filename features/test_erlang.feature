Feature: Testing an Erlang project
  Background:
   Given the following test payload
     | repository | travis-ci/travis-ci                                 |
     | commit     | 1234567                                             |
     | config     | language: erlang, otp_release: R15B, env: FOO=foo   |

  Scenario: A successful build with the default OTP release
   Given the following test payload
     | repository | travis-ci/travis-ci            |
     | commit     | 1234567                        |
     | config     | language: erlang, env: FOO=foo |
    When it starts a job
    Then it exports the given environment variables
     And it successfully clones the repository to the build dir with git
     And it successfully checks out the commit with git to the repository directory
     And it successfully switches to the erlang version: R14B04
     And it does not find the file rebar.config or Rebar.config
     And it successfully runs the script: make test
     And it closes the ssh session
     And it returns the result 0
     And it has captured the following events
       | name            | data                                          |
       | job:test:start  | started_at: [now]                             |
       | job:test:log    | log: /Using worker/                           |
       | job:test:log    | log: cd ~/builds                              |
       | job:test:log    | log: export TRAVIS_PULL_REQUEST=false         |
       | job:test:log    | log: export TRAVIS_SECURE_ENV_VARS=false      |
       | job:test:log    | log: export TRAVIS_JOB_ID=10                  |
       | job:test:log    | log: export FOO=foo                           |
       | job:test:log    | log: git clone                                |
       | job:test:log    | log: cd travis-ci/travis-ci                   |
       | job:test:log    | log: git checkout                             |
       | job:test:log    | log: source /home/vagrant/otp/R14B04/activate |
       | job:test:log    | log: make test                                |
       | job:test:log    | log: /Done.* 0/                               |
       | job:test:finish | finished_at: [now], result: 0                 |

  Scenario: A successful build with given OTP release
    When it starts a job
    Then it exports the given environment variables
     And it successfully clones the repository to the build dir with git
     And it successfully checks out the commit with git to the repository directory
     And it successfully switches to the erlang version: R15B
     And it does not find the file rebar.config or Rebar.config
     And it successfully runs the script: make test
     And it closes the ssh session
     And it returns the result 0
     And it has captured the following events
       | name            | data                                          |
       | job:test:start  | started_at: [now]                             |
       | job:test:log    | log: /Using worker/                           |
       | job:test:log    | log: cd ~/builds                              |
       | job:test:log    | log: export TRAVIS_PULL_REQUEST=false         |
       | job:test:log    | log: export TRAVIS_SECURE_ENV_VARS=false      |
       | job:test:log    | log: export TRAVIS_JOB_ID=10                  |
       | job:test:log    | log: export FOO=foo                           |
       | job:test:log    | log: git clone                                |
       | job:test:log    | log: cd travis-ci/travis-ci                   |
       | job:test:log    | log: git checkout                             |
       | job:test:log    | log: source /home/vagrant/otp/R15B/activate   |
       | job:test:log    | log: make test                                |
       | job:test:log    | log: /Done.* 0/                               |
       | job:test:finish | finished_at: [now], result: 0                 |

  Scenario: A successful build with system-wide rebar
    When it starts a job
    Then it exports the given environment variables
     And it successfully clones the repository to the build dir with git
     And it successfully checks out the commit with git to the repository directory
     And it successfully switches to the erlang version: R15B
     And there is no local rebar in the repository
     And it finds a file rebar.config and successfully installs dependencies with rebar
     And it successfully runs the script: rebar compile && rebar skip_deps=true eunit
     And it closes the ssh session
     And it returns the result 0
     And it has captured the following events
       | name            | data                                    |
       | job:test:start  | started_at: [now]                       |
       | job:test:log    | log: /Using worker/                     |
       | job:test:log    | log: cd ~/builds                        |
       | job:test:log    | log: export TRAVIS_PULL_REQUEST=false   |
       | job:test:log    | log: export TRAVIS_SECURE_ENV_VARS=false|
       | job:test:log    | log: export TRAVIS_JOB_ID=10            |
       | job:test:log    | log: export FOO=foo                     |
       | job:test:log    | log: git clone                          |
       | job:test:log    | log: cd travis-ci/travis-ci             |
       | job:test:log    | log: git checkout                       |
       | job:test:log    | log: /activate/                         |
       | job:test:log    | log: rebar get-deps                     |
       | job:test:log    | log: /eunit/                            |
       | job:test:log    | log: /Done.* 0/                         |
       | job:test:finish | finished_at: [now], result: 0           |

  Scenario: The repository can not be cloned
    When it starts a job
    Then it exports the given environment variables
     And it fails to clone the repository to the build dir with git
     And it closes the ssh session
     And it returns the result 1

  Scenario: The commit can not be checked out
    When it starts a job
    Then it exports the given environment variables
     And it successfully clones the repository to the build dir with git
     And it fails to check out the commit with git to the repository directory
     And it closes the ssh session
     And it returns the result 1

  Scenario: The erlang version can not be activated
    When it starts a job
    Then it exports the given environment variables
     And it successfully clones the repository to the build dir with git
     And it successfully checks out the commit with git to the repository directory
     And it fails to switch to the erlang version: R15B
     And it closes the ssh session
     And it returns the result 1

  Scenario: dependencies cannot be installed
    When it starts a job
    Then it exports the given environment variables
     And it successfully clones the repository to the build dir with git
     And it successfully checks out the commit with git to the repository directory
     And it successfully switches to the erlang version: R15B
     And there is no local rebar in the repository
     And it finds a file rebar.config but fails to install dependencies with rebar
     And it closes the ssh session
     And it returns the result 1

  Scenario: A failing build
    When it starts a job
    Then it exports the given environment variables
     And it successfully clones the repository to the build dir with git
     And it successfully checks out the commit with git to the repository directory
     And it successfully switches to the erlang version: R15B
     And it does not find the file rebar.config or Rebar.config
     And it fails to run the script: make test
     And it closes the ssh session
     And it returns the result 1

