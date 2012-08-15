Feature: Testing a Clojure project

  Background:
   Given the following test payload
     | repository | travis-ci/travis-ci             |
     | commit     | 1234567                         |
     | config     | language: clojure, env: FOO=foo |

  Scenario: A successful build
    When it starts a job
    Then it exports the given environment variables
     And it successfully clones the repository to the build dir with git
     And it successfully checks out the commit with git to the repository directory
     And it exports the line TRAVIS_JDK_VERSION=default
     And it successfully switches to the jdk version: default
     And it announces active jdk version
     And it announces active leiningen version
     And it successfully installs dependencies with lein
     And it successfully runs the script: lein test
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
       | job:test:log    | log: jdk_switcher use default            |
       | job:test:log    | log: java -version                       |
       | job:test:log    | log: javac -version                      |
       | job:test:log    | log: lein version                        |
       | job:test:log    | log: lein deps                           |
       | job:test:log    | log: lein test                           |
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

  Scenario: The lein dependencies can not be installed
    When it starts a job
    Then it exports the given environment variables
     And it successfully clones the repository to the build dir with git
     And it successfully checks out the commit with git to the repository directory
     And it exports the line TRAVIS_JDK_VERSION=default
     And it successfully switches to the jdk version: default
     And it announces active jdk version
     And it announces active leiningen version
     And it fails to install dependencies with lein
     And it closes the ssh session
     And it returns the result 1

  Scenario: The jdk version can not be activated
    When it starts a job
    Then it exports the given environment variables
     And it successfully clones the repository to the build dir with git
     And it successfully checks out the commit with git to the repository directory
     And it exports the line TRAVIS_JDK_VERSION=default
     And it fails to switch to the jdk version: default
     And it closes the ssh session
     And it returns the result 1

  Scenario: A failing build
    When it starts a job
    Then it exports the given environment variables
     And it successfully clones the repository to the build dir with git
     And it successfully checks out the commit with git to the repository directory
     And it exports the line TRAVIS_JDK_VERSION=default
     And it successfully switches to the jdk version: default
     And it announces active jdk version
     And it announces active leiningen version
     And it successfully installs dependencies with lein
     And it fails to run the script: lein test
     And it closes the ssh session
     And it returns the result 1
