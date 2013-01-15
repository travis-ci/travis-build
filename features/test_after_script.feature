Feature: after_success commands

  Background:
   Given the following test payload
     | repository | travis-ci/travis-ci                                                                |
     | commit     | 1234567                                                                            |
     | config     | language: clojure, jdk: openjdk6, env: FOO=foo, after_script: ./launch-missles.sh    |

  Scenario: A successful build is wrapped up with an after_success command
    When it starts a job
    Then it exports the given environment variables
    And it successfully clones the repository to the build dir with git
    And it successfully checks out the commit with git to the repository directory
    And it exports the line TRAVIS_JDK_VERSION=openjdk6
    And it successfully switches to the jdk version: openjdk6
    And it announces active jdk version
    And it announces active leiningen version
    And it successfully installs dependencies with lein
    And it successfully runs the script: lein test
    And it executes ./launch-missles.sh after the script
    And it closes the ssh session
    And it returns the state :passed
    And it has captured the following events
       | name            | data                                      |
       | job:test:start  | started_at: [now]                         |
       | job:test:log    | log: /Using worker/                       |
       | job:test:log    | log: cd ~/builds                          |
       | job:test:log    | log: export TRAVIS_PULL_REQUEST=false     |
       | job:test:log    | log: export TRAVIS_SECURE_ENV_VARS=false  |
       | job:test:log    | log: export TRAVIS_JOB_ID=10              |
       | job:test:log    | log: export TRAVIS_BRANCH=master          |
       | job:test:log    | log: export TRAVIS_BUILD_ID=9             |
       | job:test:log    | log: export TRAVIS_BUILD_NUMBER=22        |
       | job:test:log    | log: export TRAVIS_JOB_NUMBER=22.1        |
       | job:test:log    | log: export TRAVIS_COMMIT_RANGE=a...b     |
       | job:test:log    | log: export TRAVIS_COMMIT=f4ca9d          |
       | job:test:log    | log: export FOO=foo                       |
       | job:test:log    | log: git clone                            |
       | job:test:log    | log: cd travis-ci/travis-ci               |
       | job:test:log    | log: git checkout                         |
       | job:test:log    | log: /export TRAVIS_JDK_VERSION=openjdk6/ |
       | job:test:log    | log: jdk_switcher use openjdk6            |
       | job:test:log    | log: java -version                        |
       | job:test:log    | log: javac -version                       |
       | job:test:log    | log: lein version                         |
       | job:test:log    | log: lein deps                            |
       | job:test:log    | log: lein test                            |
       | job:test:log    | log: export TRAVIS_TEST_RESULT=0          |
       | job:test:log    | log: ./launch-missles.sh                  |
       | job:test:log    | log: /Done.* 0/                           |
       | job:test:finish | finished_at: [now], state: :passed        |
