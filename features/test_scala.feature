Feature: Testing a Scala project

  Background:
   Given the following test payload
     | repository | travis-ci/travis-ci                         |
     | commit     | 1234567                                     |
     | config     | language: scala, scala: 2.9.1, env: FOO=foo |

  Scenario: A successful SBT build without forcing Scala version 
   Given the following test payload
     | repository | travis-ci/travis-ci                         |
     | commit     | 1234567                                     |
     | config     | language: scala, env: FOO=foo               |

    When it starts a job
    Then it exports the given environment variables
     And it successfully clones the repository to the build dir with git 
     And it successfully checks out the commit with git to the repository directory
     And it exports the line TRAVIS_SCALA_VERSION=undefined
     # think ./project          
     And it finds directory project
     And it successfully runs the script: sbt test
     And it closes the ssh session
     And it returns the status 0
     And it has captured the following events
       | name            | data                                | 
       | job:test:start  | started_at: [now]                   |
       | job:test:log    | log: /Using worker/                 | 
       | job:test:log    | log: cd ~/builds                    |
       | job:test:log    | log: export FOO=foo                 | 
       | job:test:log    | log: git clone                      |
       | job:test:log    | log: cd travis-ci/travis-ci         |
       | job:test:log    | log: git checkout                   |
       | job:test:log    | log: /export TRAVIS_SCALA_VERSION=/ |
       | job:test:log    | log: sbt test                       |
       | job:test:log    | log: /Done.* 0/                     |
       | job:test:finish | finished_at: [now], status: 0       |
  
  Scenario: A successful build with ./project directory in the repository root
    When it starts a job
    Then it exports the given environment variables
     And it successfully clones the repository to the build dir with git
     And it successfully checks out the commit with git to the repository directory
     And it exports the line TRAVIS_SCALA_VERSION=2.9.1
     # think ./project
     And it finds directory project
     And it successfully runs the script: sbt ++2.9.1 test
     And it closes the ssh session
     And it returns the status 0
     And it has captured the following events
       | name            | data                                |
       | job:test:start  | started_at: [now]                   |
       | job:test:log    | log: /Using worker/                 |
       | job:test:log    | log: cd ~/builds                    |
       | job:test:log    | log: export FOO=foo                 |
       | job:test:log    | log: git clone                      |
       | job:test:log    | log: cd travis-ci/travis-ci         |
       | job:test:log    | log: git checkout                   |
       | job:test:log    | log: /export TRAVIS_SCALA_VERSION=/ |
       | job:test:log    | log: sbt ++2.9.1 test               |
       | job:test:log    | log: /Done.* 0/                     |
       | job:test:finish | finished_at: [now], status: 0       |

  Scenario: A successful build with build.sbt file in the repository root
    When it starts a job
    Then it exports the given environment variables
     And it successfully clones the repository to the build dir with git
     And it successfully checks out the commit with git to the repository directory
     And it exports the line TRAVIS_SCALA_VERSION=2.9.1
     And it does not find directory project
     And it finds the file build.sbt
     And it successfully runs the script: sbt ++2.9.1 test
     And it closes the ssh session
     And it returns the status 0
     And it has captured the following events
       | name            | data                                |
       | job:test:start  | started_at: [now]                   |
       | job:test:log    | log: /Using worker/                 |
       | job:test:log    | log: cd ~/builds                    |
       | job:test:log    | log: export FOO=foo                 |
       | job:test:log    | log: git clone                      |
       | job:test:log    | log: cd travis-ci/travis-ci         |
       | job:test:log    | log: git checkout                   |
       | job:test:log    | log: /export TRAVIS_SCALA_VERSION=/ |
       | job:test:log    | log: sbt ++2.9.1 test               |
       | job:test:log    | log: /Done.* 0/                     |
       | job:test:finish | finished_at: [now], status: 0       |

  Scenario: The repository can not be cloned
    When it starts a job
    Then it exports the given environment variables
     And it fails to clone the repository to the build dir with git
     And it closes the ssh session
     And it returns the status 1

  Scenario: The commit can not be checked out
    When it starts a job
    Then it exports the given environment variables
     And it successfully clones the repository to the build dir with git
     And it fails to check out the commit with git to the repository directory
     And it closes the ssh session
     And it returns the status 1

  Scenario: A failing build
    When it starts a job
    Then it exports the given environment variables
     And it successfully clones the repository to the build dir with git
     And it successfully checks out the commit with git to the repository directory
     And it exports the line TRAVIS_SCALA_VERSION=2.9.1
     # think ./project
     And it finds directory project
     And it fails to run the script: sbt ++2.9.1 test
     And it closes the ssh session
     And it returns the status 1
