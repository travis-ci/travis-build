# Travis Build [![Build Status](https://travis-ci.org/travis-ci/travis-build.png?branch=master)](https://travis-ci.org/travis-ci/travis-build)

Travis Build is a library that [Travis
Workers](https://github.com/travis-ci/worker) use to generate a shell
based build script which is then uploaded to the VMs using SSH and executed,
with the resulting output streamed back to Travis.

This code base has gone through several iterations of development, and was
originally extracted from [Travis
Worker](https://github.com/travis-ci/worker), before taking its current
form.

## Running test suites

Since the specs run the generated build script, we recommend running it in a
virtual machine to contain the changes. There's a Vagrantfile in this
repository, so you can use [Vagrant](http://www.vagrantup.com) for this:

    vagrant up
    vagrant ssh
    cd /vagrant
    bundle exec rspec spec

If you wish to just run the specs, you can just run `bundle exec rspec spec`.

## Use as addon for CLI

You can set travis-build up as a plugin for the [command line client](https://github.com/travis-ci/travis.rb):

    ln -s PATH_TO_TRAVIS_BUILD ~/.travis/travis-build
    gem install bundler
    bundle install --gemfile ~/.travis/travis-build/Gemfile

This will add the `compile` command to travis CLI, which produces
the bash script that runs the specified job, except that the secure environment
variables are not defined, and that the build matrix expansion is not considered.

### _Important_

The resulting script contains commands that make changes to the system on which it is executed
(e.g., edit `/etc/resolv.conf`, install software).
Some require `sudo` privileges and they are not easily undone.

It is highly recommended that you run this on a virtual machine.

### Invocation

The command can be invoked in 3 ways:

1. Without an argument, it produces the bash script for the local `.travis.yml` without considering `env` and `matrix` values
(`travis-build` is unable to expand these keys correctly).

    `$ travis compile`

1. With a single integer, it produces the script for the given build
(or the first job of that build matrix).

    `$ travis compile 8`

1. With an argument of the form `M.N`, it produces the bash script for the job `M.N`.

    `$ travis compile 351.2`

The resultant script can be used on a (virtual) machine that closely mimics Travis CI's build
environment to aid you in debugging the build failures.

## License & copyright information

See LICENSE file.

Copyright (c) 2011-2016 [Travis CI development
team](https://github.com/travis-ci).
