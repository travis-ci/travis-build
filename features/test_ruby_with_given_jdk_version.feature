Feature: Testing a Ruby project with a given JDK version

  Background:
   Given the following test payload
     | repository | travis-ci/travis-ci                                                |
     | commit     | 1234567                                                            |
     | config     | rvm: jruby, jdk: openjdk6, env: FOO=foo, gemfile: gemfiles/Gemfile |

  Scenario: A successful build
    When it starts a job
    Then it exports the given environment variables
     And it successfully clones the repository to the build dir with git
     And it successfully checks out the commit with git to the repository directory
     And it exports the line TRAVIS_JDK_VERSION=openjdk6
     And it exports the line TRAVIS_RUBY_VERSION=jruby
     And it successfully switches to the jdk version: openjdk6
     And it announces active jdk version
     And it successfully switches to the ruby version: jruby
     And it announces active ruby version
     And it does not find the file gemfiles/Gemfile
     And it successfully runs the script: rake
     And it closes the ssh session
     And it returns the result 0
     And it has captured the following events
       | name            | data                                       |
       | job:test:start  | started_at: [now]                          |
       | job:test:log    | log: /Using worker/                        |
       | job:test:log    | log: cd ~/builds                           |
       | job:test:log    | log: export TRAVIS_PULL_REQUEST=false      |
       | job:test:log    | log: export TRAVIS_SECURE_ENV_VARS=false   |
       | job:test:log    | log: export TRAVIS_JOB_ID=10               |
       | job:test:log    | log: export FOO=foo                        |
       | job:test:log    | log: git clone                             |
       | job:test:log    | log: cd travis-ci/travis-ci                |
       | job:test:log    | log: git checkout                          |
       | job:test:log    | log: export TRAVIS_JDK_VERSION=openjdk6    |
       | job:test:log    | log: export TRAVIS_RUBY_VERSION=jruby      |
       | job:test:log    | log: jdk_switcher use openjdk6             |
       | job:test:log    | log: java -version                         |
       | job:test:log    | log: javac -version                        |
       | job:test:log    | log: rvm use jruby                         |
       | job:test:log    | log: ruby --version                        |
       | job:test:log    | log: gem --version                         |
       | job:test:log    | log: rake                                  |
       | job:test:log    | log: /Done.* 0/                            |
       | job:test:finish | finished_at: [now], result: 0              |

  Scenario: A successful build with a Gemfile
    When it starts a job
    Then it exports the given environment variables
     And it successfully clones the repository to the build dir with git
     And it successfully checks out the commit with git to the repository directory
     And it exports the line TRAVIS_JDK_VERSION=openjdk6
     And it exports the line TRAVIS_RUBY_VERSION=jruby
     And it successfully switches to the jdk version: openjdk6
     And it announces active jdk version
     And it successfully switches to the ruby version: jruby
     And it announces active ruby version
     And it finds a file gemfiles/Gemfile and successfully installs dependencies with bundle
     And it successfully runs the script: bundle exec rake
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
       | job:test:log    | log: export TRAVIS_JDK_VERSION=openjdk6   |
       | job:test:log    | log: export TRAVIS_RUBY_VERSION=jruby     |
       | job:test:log    | log: jdk_switcher use openjdk6            |
       | job:test:log    | log: java -version                        |
       | job:test:log    | log: javac -version                       |
       | job:test:log    | log: rvm use jruby                        |
       | job:test:log    | log: ruby --version                       |
       | job:test:log    | log: gem --version                        |
       | job:test:log    | log: /export BUNDLE_GEMFILE=/             |
       | job:test:log    | log: bundle install                       |
       | job:test:log    | log: bundle exec rake                     |
       | job:test:log    | log: /Done.* 0/                           |
       | job:test:finish | finished_at: [now], result: 0             |

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
     And it exports the line TRAVIS_JDK_VERSION=openjdk6
     And it exports the line TRAVIS_RUBY_VERSION=jruby
     And it fails to switch to the jdk version: openjdk6
     And it closes the ssh session
     And it returns the result 1

  Scenario: The ruby version can not be activated
    When it starts a job
    Then it exports the given environment variables
     And it successfully clones the repository to the build dir with git
     And it successfully checks out the commit with git to the repository directory
     And it exports the line TRAVIS_JDK_VERSION=openjdk6
     And it exports the line TRAVIS_RUBY_VERSION=jruby
     And it successfully switches to the jdk version: openjdk6
     And it announces active jdk version
     And it fails to switch to the ruby version: jruby
     And it closes the ssh session
     And it returns the result 1

  Scenario: The bundle can not be installed
    When it starts a job
    Then it exports the given environment variables
     And it successfully clones the repository to the build dir with git
     And it successfully checks out the commit with git to the repository directory
     And it exports the line TRAVIS_JDK_VERSION=openjdk6
     And it exports the line TRAVIS_RUBY_VERSION=jruby
     And it successfully switches to the jdk version: openjdk6
     And it announces active jdk version
     And it successfully switches to the ruby version: jruby
     And it announces active ruby version
     And it finds a file gemfiles/Gemfile but fails to install dependencies with bundle
     And it closes the ssh session
     And it returns the result 1

  Scenario: The build fails
    When it starts a job
    Then it exports the given environment variables
     And it successfully clones the repository to the build dir with git
     And it successfully checks out the commit with git to the repository directory
     And it exports the line TRAVIS_JDK_VERSION=openjdk6
     And it exports the line TRAVIS_RUBY_VERSION=jruby
     And it successfully switches to the jdk version: openjdk6
     And it announces active jdk version
     And it successfully switches to the ruby version: jruby
     And it announces active ruby version
     And it does not find the file gemfiles/Gemfile
     And it fails to run the script: rake
     And it closes the ssh session
     And it returns the result 1

