Feature: Testing a Php project

  Background:
   Given the following test payload
     | repository | travis-ci/travis-ci                                           |
     | commit     | 1234567                                                       |
     | config     | language: php, php: 5.3.6, env: FOO=foo, composer_args: --dev |

  Scenario: A successful build
    When it starts a job
    Then it exports the given environment variables
     And it successfully clones the repository to the build dir with git
     And it successfully checks out the commit with git to the repository directory
     And it exports the line TRAVIS_PHP_VERSION=5.3.6
     And it successfully switches to the php version: 5.3.6
     And it announces active php version
     And it does not find the file composer.json
     And it successfully runs the script: phpunit
     And it closes the ssh session
     And it returns the result 0
     And it has captured the following events
       | name            | data                                    |
       | job:test:start  | started_at: [now]                       |
       | job:test:log    | log: /Using worker/                     |
       | job:test:log    | log: cd ~/builds                        |
       | job:test:log    | log: export TRAVIS_PULL_REQUEST=false   |
       | job:test:log    | log: export TRAVIS_SECURE_ENV_VARS=false|
       | job:test:log    | log: export TRAVIS_JOB_ID=10            |
       | job:test:log    | log: export FOO=foo                     |
       | job:test:log    | log: git clone                          |
       | job:test:log    | log: cd travis-ci/travis-ci             |
       | job:test:log    | log: git checkout                       |
       | job:test:log    | log: /export TRAVIS_PHP_VERSION=5.3.6/  |
       | job:test:log    | log: phpenv global 5.3.6                |
       | job:test:log    | log: php --version                      |
       | job:test:log    | log: phpunit                            |
       | job:test:log    | log: /Done.* 0/                         |
       | job:test:finish | finished_at: [now], result: 0           |

  #Scenario: A successful build with a composer.json file
    #When it starts a job
    #Then it exports the given environment variables
     #And it successfully clones the repository to the build dir with git
     #And it successfully checks out the commit with git to the repository directory
     #And it successfully switches to the php version: 5.3.6
     #And it announces active php version
     #And it finds a file composer.json and successfully installs dependencies with composer
     #And it successfully runs the script: phpunit
     #And it closes the ssh session
     #And it returns the result 0
     #And it has captured the following events
       #| name            | data                          |
       #| job:test:start  | started_at: [now]             |
       #| job:test:log    | log: /Using worker/           |
       #| job:test:log    | log: cd ~/builds              |
       #| job:test:log    | log: export FOO=foo           |
       #| job:test:log    | log: git clone                |
       #| job:test:log    | log: cd travis-ci/travis-ci   |
       #| job:test:log    | log: git checkout             |
       #| job:test:log    | log: phpenv global 5.3.6  |
       #| job:test:log    | log: composer install --dev   |
       #| job:test:log    | log: phpunit                  |
       #| job:test:log    | log: /Done.* 0/               |
       #| job:test:finish | finished_at: [now], result: 0 |

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

  Scenario: The php version can not be activated
    When it starts a job
    Then it exports the given environment variables
     And it successfully clones the repository to the build dir with git
     And it successfully checks out the commit with git to the repository directory
     And it exports the line TRAVIS_PHP_VERSION=5.3.6
     And it fails to switch to the php version: 5.3.6
     And it closes the ssh session
     And it returns the result 1

  #Scenario: The composer packages can not be installed
    #When it starts a job
    #Then it exports the given environment variables
     #And it successfully clones the repository to the build dir with git
     #And it successfully checks out the commit with git to the repository directory
     #And it successfully switches to the php version: 5.3.6
     #And it finds a file composer.json but fails to install dependencies with composer
     #And it closes the ssh session
     #And it returns the result 1

  Scenario: A failing build
    When it starts a job
    Then it exports the given environment variables
     And it successfully clones the repository to the build dir with git
     And it successfully checks out the commit with git to the repository directory
     And it exports the line TRAVIS_PHP_VERSION=5.3.6
     And it successfully switches to the php version: 5.3.6
     And it announces active php version
     And it does not find the file composer.json
     And it fails to run the script: phpunit
     And it closes the ssh session
     And it returns the result 1

