Feature: Testing a Node.js project

  Background:
   Given the following test payload
     | repository | travis-ci/travis-ci                                                      |
     | commit     | 1234567                                                                  |
     | config     | language: node.js, nodejs_version: 0.4.12, env: FOO=foo, npm_args: --dev |

  Scenario: A successful build
    When it starts a job
    Then it exports the given environment variables
     And it successfully clones the repository to the build dir with git
     And it successfully checks out the commit with git to the repository directory
     And it successfully switches to the node.js version: 0.4.12
     And it does not find the file package.json
     And it successfully runs the script: make test
     And it closes the ssh session
     And it returns true
     And it has captured the following events
       | name            | data                             |
       | job:test:start  | started_at: [now]                |
       | job:test:log    | output: /Using worker/           |
       | job:test:log    | output: export FOO               |
       | job:test:log    | output: git clone                |
       | job:test:log    | output: git checkout             |
       | job:test:log    | output: nvm use v0.4.12          |
       | job:test:log    | output: make test                |
       | job:test:log    | output: /Done.* true/            |
       | job:test:finish | finished_at: [now], result: true |

  Scenario: A successful with a package.json file
    When it starts a job
    Then it exports the given environment variables
     And it successfully clones the repository to the build dir with git
     And it successfully checks out the commit with git to the repository directory
     And it successfully switches to the node.js version: 0.4.12
     And it finds a file package.json and successfully installs the npm packages
     And it successfully runs the script: npm test
     And it closes the ssh session
     And it returns true
     And it has captured the following events
       | name            | data                             |
       | job:test:start  | started_at: [now]                |
       | job:test:log    | output: /Using worker/           |
       | job:test:log    | output: export FOO               |
       | job:test:log    | output: git clone                |
       | job:test:log    | output: git checkout             |
       | job:test:log    | output: nvm use v0.4.12          |
       | job:test:log    | output: npm install --dev        |
       | job:test:log    | output: npm test                 |
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

  Scenario: The node.js version can not be activated
    When it starts a job
    Then it exports the given environment variables
     And it successfully clones the repository to the build dir with git
     And it successfully checks out the commit with git to the repository directory
     And it fails to switch to the node.js version: 0.4.12
     And it closes the ssh session
     And it returns false

  Scenario: The bundle can not be installed
    When it starts a job
    Then it exports the given environment variables
     And it successfully clones the repository to the build dir with git
     And it successfully checks out the commit with git to the repository directory
     And it successfully switches to the node.js version: 0.4.12
     And it finds a file package.json but fails to install the npm packages
     And it closes the ssh session
     And it returns false

  Scenario: A failing build
    When it starts a job
    Then it exports the given environment variables
     And it successfully clones the repository to the build dir with git
     And it successfully checks out the commit with git to the repository directory
     And it successfully switches to the node.js version: 0.4.12
     And it does not find the file package.json
     And it fails to run the script: make test
     And it closes the ssh session
     And it returns false


