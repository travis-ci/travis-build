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
     And it successfully installs the lein dependencies
     And it successfully runs the script: lein test
     And it closes the ssh session
     And it returns true
     And it has captured the following events
       | name            | data                             |
       | job:test:start  | started_at: [now]                |
       | job:test:log    | output: /Using worker/           |
       | job:test:log    | output: export FOO               |
       | job:test:log    | output: git clone                |
       | job:test:log    | output: git checkout             |
       | job:test:log    | output: lein deps                |
       | job:test:log    | output: lein test                |
       | job:test:log    | output: /Done.* true/            |
       | job:test:finish | finished_at: [now], result: true |

  Scenario: The repository can not be cloned
    When it starts a job
    Then it exports the given environment variables
     And it fails to clone the repository to the build dir with git
     And it closes the ssh session
     And it returns false

  Scenario: The commit can not be checked out
    When it starts a job
    Then it exports the given environment variables
     And it successfully clones the repository to the build dir with git
     And it fails to check out the commit with git to the repository directory
     And it closes the ssh session
     And it returns false

  Scenario: The lein dependencies can not be installed
    When it starts a job
    Then it exports the given environment variables
     And it successfully clones the repository to the build dir with git
     And it successfully checks out the commit with git to the repository directory
     And it fails to install the lein dependencies
     And it closes the ssh session
     And it returns false

  Scenario: A failing build
    When it starts a job
    Then it exports the given environment variables
     And it successfully clones the repository to the build dir with git
     And it successfully checks out the commit with git to the repository directory
     And it successfully installs the lein dependencies
     And it fails to run the script: lein test
     And it closes the ssh session
     And it returns false
