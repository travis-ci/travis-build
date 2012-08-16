Feature: Testing a Scala project

  Background:
   Given the following test payload
     | repository | travis-ci/travis-ci                         |
     | commit     | 1234567                                     |
     | config     | language: scala, scala: 2.9.1, env: FOO=foo |

  Scenario: A successful build with ./project directory in the repository root
    When it starts a job
    Then it exports the given environment variables
     And it successfully clones the repository to the build dir with git
     And it successfully checks out the commit with git to the repository directory
     And it exports the line TRAVIS_JDK_VERSION=default
     And it exports the line TRAVIS_SCALA_VERSION=2.9.1
     And it successfully switches to the jdk version: default
     And it announces active jdk version
     # think ./project
     And it finds directory project
     And it successfully runs the script: sbt ++2.9.1 test
     And it closes the ssh session
     And it returns the result 0
     And it has captured the following events
       | name            | data                                      |
       | job:test:start  | started_at: [now]                         |
       | job:test:log    | log: /Using worker/                       |
       | job:test:log    | log: cd ~/builds                          |
       | job:test:log    | log: export TRAVIS_PULL_REQUEST=false     |
       | job:test:log    | log: export TRAVIS_SECURE_ENV_VARS=false  |
       | job:test:log    | log: export TRAVIS_JOB_ID=10              |
       | job:test:log    | log: export FOO=foo                       |
       | job:test:log    | log: git clone                            |
       | job:test:log    | log: cd travis-ci/travis-ci               |
       | job:test:log    | log: git checkout                         |
       | job:test:log    | log: /export TRAVIS_JDK_VERSION=default/  |
       | job:test:log    | log: /export TRAVIS_SCALA_VERSION=/       |
       | job:test:log    | log: jdk_switcher use default             |
       | job:test:log    | log: java -version                        |
       | job:test:log    | log: javac -version                       |
       | job:test:log    | log: sbt ++2.9.1 test                     |
       | job:test:log    | log: /Done.* 0/                           |
       | job:test:finish | finished_at: [now], result: 0             |

  Scenario: A successful build with build.sbt file in the repository root
    When it starts a job
    Then it exports the given environment variables
     And it successfully clones the repository to the build dir with git
     And it successfully checks out the commit with git to the repository directory
     And it exports the line TRAVIS_JDK_VERSION=default
     And it exports the line TRAVIS_SCALA_VERSION=2.9.1
     And it successfully switches to the jdk version: default
     And it announces active jdk version
     And it does not find directory project
     And it finds the file build.sbt
     And it successfully runs the script: sbt ++2.9.1 test
     And it closes the ssh session
     And it returns the result 0
     And it has captured the following events
       | name            | data                                     |
       | job:test:start  | started_at: [now]                        |
       | job:test:log    | log: /Using worker/                      |
       | job:test:log    | log: cd ~/builds                         |
       | job:test:log    | log: export TRAVIS_PULL_REQUEST=false    |
       | job:test:log    | log: export TRAVIS_SECURE_ENV_VARS=false |
       | job:test:log    | log: export TRAVIS_JOB_ID=10             |
       | job:test:log    | log: export FOO=foo                      |
       | job:test:log    | log: git clone                           |
       | job:test:log    | log: cd travis-ci/travis-ci              |
       | job:test:log    | log: git checkout                        |
       | job:test:log    | log: /export TRAVIS_JDK_VERSION=default/ |
       | job:test:log    | log: /export TRAVIS_SCALA_VERSION=/      |
       | job:test:log    | log: jdk_switcher use default            |
       | job:test:log    | log: java -version                       |
       | job:test:log    | log: javac -version                      |
       | job:test:log    | log: sbt ++2.9.1 test                    |
       | job:test:log    | log: /Done.* 0/                          |
       | job:test:finish | finished_at: [now], result: 0            |


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

  Scenario: The jdk version can not be activated
    When it starts a job
    Then it exports the given environment variables
     And it successfully clones the repository to the build dir with git
     And it successfully checks out the commit with git to the repository directory
     And it exports the line TRAVIS_JDK_VERSION=default
     And it exports the line TRAVIS_SCALA_VERSION=2.9.1
     And it fails to switch to the jdk version: default
     And it closes the ssh session
     And it returns the result 1

  Scenario: A failing build
    When it starts a job
    Then it exports the given environment variables
     And it successfully clones the repository to the build dir with git
     And it successfully checks out the commit with git to the repository directory
     And it exports the line TRAVIS_JDK_VERSION=default
     And it exports the line TRAVIS_SCALA_VERSION=2.9.1
     And it successfully switches to the jdk version: default
     And it announces active jdk version
     # think ./project
     And it finds directory project
     And it fails to run the script: sbt ++2.9.1 test
     And it closes the ssh session
     And it returns the result 1
