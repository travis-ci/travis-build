Feature: Testing a Ruby project

  Background:
   Given the following test payload
     | repository | travis-ci/travis-ci                                 |
     | commit     | 1234567                                             |
     | config     | rvm: 1.9.2, env: FOO=foo, gemfile: gemfiles/Gemfile |

  Scenario: A successful build
    When it starts a job
    Then it exports the given environment variables
     And it successfully clones the repository to the build dir with git
     And it successfully checks out the commit with git to the repository directory
     And it successfully switches to the ruby version: 1.9.2
     And it does not find the file gemfiles/Gemfile
     And it successfully runs the script: rake
     And it closes the ssh session
     And it returns true
     And it has captured the following events
       | name            | data                             |
       | job:test:start  | started_at: [now]                |
       | job:test:log    | output: /Using worker/           |
       | job:test:log    | output: cd ~/builds              |
       | job:test:log    | output: export FOO               |
       | job:test:log    | output: git clone                |
       | job:test:log    | output: cd travis-ci/travis-ci   |
       | job:test:log    | output: git checkout             |
       | job:test:log    | output: rvm use 1.9.2            |
       | job:test:log    | output: rake                     |
       | job:test:log    | output: /Done.* true/            |
       | job:test:finish | finished_at: [now], result: true |

  Scenario: A successful build with a Gemfile
    When it starts a job
    Then it exports the given environment variables
     And it successfully clones the repository to the build dir with git
     And it successfully checks out the commit with git to the repository directory
     And it successfully switches to the ruby version: 1.9.2
     And it finds a file gemfiles/Gemfile and successfully installs the bundle
     And it successfully runs the script: bundle exec rake
     And it closes the ssh session
     And it returns true
     And it has captured the following events
       | name            | data                             |
       | job:test:start  | started_at: [now]                |
       | job:test:log    | output: /Using worker/           |
       | job:test:log    | output: cd ~/builds              |
       | job:test:log    | output: export FOO               |
       | job:test:log    | output: git clone                |
       | job:test:log    | output: cd travis-ci/travis-ci   |
       | job:test:log    | output: git checkout             |
       | job:test:log    | output: rvm use 1.9.2            |
       | job:test:log    | output: export BUNDLE_GEMFILE    |
       | job:test:log    | output: bundle install           |
       | job:test:log    | output: bundle exec rake         |
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

  Scenario: The ruby version can not be activated
    When it starts a job
    Then it exports the given environment variables
     And it successfully clones the repository to the build dir with git
     And it successfully checks out the commit with git to the repository directory
     And it fails to switch to the ruby version: 1.9.2
     And it closes the ssh session
     And it returns false

  Scenario: The bundle can not be installed
    When it starts a job
    Then it exports the given environment variables
     And it successfully clones the repository to the build dir with git
     And it successfully checks out the commit with git to the repository directory
     And it successfully switches to the ruby version: 1.9.2
     And it finds a file gemfiles/Gemfile but fails to install the bundle
     And it closes the ssh session
     And it returns false

  Scenario: The build fails
    When it starts a job
    Then it exports the given environment variables
     And it successfully clones the repository to the build dir with git
     And it successfully checks out the commit with git to the repository directory
     And it successfully switches to the ruby version: 1.9.2
     And it does not find the file gemfiles/Gemfile
     And it fails to run the script: rake
     And it closes the ssh session
     And it returns false

