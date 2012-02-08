Feature: Testing a Perl project
  Background:
    Given the following test payload
     | repository | travis-ci/travis-ci                          |
     | commit     | 1234567                                      |
     | config     | language: perl, perlbrew: 5.12, env: FOO=foo |

  Scenario: A successful build
    When it starts a job
    Then it exports the given environment variables
     And it successfully clones the repository to the build dir with git
     And it successfully checks out the commit with git to the repository directory
     And it exports the line TRAVIS_PERL_VERSION=5.12
     And it successfully switches to the perl version: 5.12
     And it announces active perl version
     And it successfully runs the script: cpanm . -v --no-interactive
     And it closes the ssh session
     And it returns the status 0
     And it has captured the following events
       | name            | data                                   |
       | job:test:start  | started_at: [now]                      |
       | job:test:log    | log: /Using worker/                    |
       | job:test:log    | log: cd ~/builds                       |
       | job:test:log    | log: export FOO=foo                    |
       | job:test:log    | log: git clone                         |
       | job:test:log    | log: cd travis-ci/travis-ci            |
       | job:test:log    | log: git checkout                      |
       | job:test:log    | log: /export TRAVIS_PERL_VERSION=5.12/ |
       | job:test:log    | log: perlbrew use 5.12                 |
       | job:test:log    | log: perl --version                    |
       | job:test:log    | log: cpanm . -v --no-interactive       |
       | job:test:log    | log: /Done.* 0/                        |
       | job:test:finish | finished_at: [now], status: 0          |

