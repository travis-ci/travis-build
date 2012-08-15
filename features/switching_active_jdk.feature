Feature: Switching JDKs when testing a Clojure project

  Scenario: A successful build with OpenJDK 7
    Given the following test payload
     | repository | travis-ci/travis-ci                            |
     | commit     | 1234567                                        |
     | config     | language: clojure, env: FOO=foo, jdk: openjdk7 |
    When it starts a job
    Then it exports the given environment variables
     And it successfully clones the repository to the build dir with git
     And it successfully checks out the commit with git to the repository directory
     And it exports the line TRAVIS_JDK_VERSION=openjdk7
     And it successfully switches to the jdk version: openjdk7
     And it announces active jdk version
     And it announces active leiningen version
     And it successfully installs dependencies with lein
     And it successfully runs the script: lein test
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
       | job:test:log    | log: /export TRAVIS_JDK_VERSION=openjdk7/ |
       | job:test:log    | log: jdk_switcher use openjdk7            |
       | job:test:log    | log: java -version                        |
       | job:test:log    | log: javac -version                       |
       | job:test:log    | log: lein version                         |
       | job:test:log    | log: lein deps                            |
       | job:test:log    | log: lein test                            |
       | job:test:log    | log: /Done.* 0/                           |
       | job:test:finish | finished_at: [now], result: 0             |


  Scenario: A successful build with Oracle JDK 7
    Given the following test payload
     | repository | travis-ci/travis-ci                              |
     | commit     | 1234567                                          |
     | config     | language: clojure, env: FOO=foo, jdk: oraclejdk7 |
    When it starts a job
    Then it exports the given environment variables
     And it successfully clones the repository to the build dir with git
     And it successfully checks out the commit with git to the repository directory
     And it exports the line TRAVIS_JDK_VERSION=oraclejdk7
     And it successfully switches to the jdk version: oraclejdk7
     And it announces active jdk version
     And it announces active leiningen version
     And it successfully installs dependencies with lein
     And it successfully runs the script: lein test
     And it closes the ssh session
     And it returns the result 0
     And it has captured the following events
       | name            | data                                        |
       | job:test:start  | started_at: [now]                           |
       | job:test:log    | log: /Using worker/                         |
       | job:test:log    | log: cd ~/builds                            |
       | job:test:log    | log: export TRAVIS_PULL_REQUEST=false       |
       | job:test:log    | log: export TRAVIS_SECURE_ENV_VARS=false    |
       | job:test:log    | log: export TRAVIS_JOB_ID=10                |
       | job:test:log    | log: export FOO=foo                         |
       | job:test:log    | log: git clone                              |
       | job:test:log    | log: cd travis-ci/travis-ci                 |
       | job:test:log    | log: git checkout                           |
       | job:test:log    | log: /export TRAVIS_JDK_VERSION=oraclejdk7/ |
       | job:test:log    | log: jdk_switcher use oraclejdk7            |
       | job:test:log    | log: java -version                          |
       | job:test:log    | log: javac -version                         |
       | job:test:log    | log: lein version                           |
       | job:test:log    | log: lein deps                              |
       | job:test:log    | log: lein test                              |
       | job:test:log    | log: /Done.* 0/                             |
       | job:test:finish | finished_at: [now], result: 0               |
