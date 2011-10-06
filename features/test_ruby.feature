Feature: Testing a Ruby project

  Background:
   Given the following test payload
     | repository | travis-ci/travis-ci      |
     | commit     | 1234567                  |
     | config     | rvm: 1.9.2, env: FOO=foo |

  Scenario: A successful build
    When it starts a job
    Then it exports the given environment variables
     And it successfully clones the repository to the build dir with git
     And it successfully checks out the commit with git to the repository directory
     And it successfully switches to the ruby version: 1.9.2
     And it finds the following file does not exist: Gemfile
     And it successfully runs the script: rake
     And it closes the ssh session
     And it returns true

  Scenario: A failing build
    When it starts a job
    Then it exports the given environment variables
     And it successfully clones the repository to the build dir with git
     And it successfully checks out the commit with git to the repository directory
     And it successfully switches to the ruby version: 1.9.2
     And it finds the following file does not exist: Gemfile
     And it fails to run the script: rake
     And it closes the ssh session
     And it returns false

  Scenario: A successful build with a Gemfile
    When it starts a job
    Then it exports the given environment variables
     And it successfully clones the repository to the build dir with git
     And it successfully checks out the commit with git to the repository directory
     And it successfully switches to the ruby version: 1.9.2
     And it finds the Gemfile and successfully installs the bundle
     And it successfully runs the script: bundle exec rake
     And it closes the ssh session
     And it returns true

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
     And it finds the Gemfile and fails to install the bundle
     And it closes the ssh session
     And it returns false

