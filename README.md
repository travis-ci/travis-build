# Travis Build [![Build Status](https://travis-ci.org/travis-ci/travis-build.svg?branch=master)](https://travis-ci.org/travis-ci/travis-build)

Travis Build is a library that [Travis
Workers](https://github.com/travis-ci/worker) use to generate a shell
based build script which is then uploaded to the VMs using SSH and executed,
with the resulting output streamed back to Travis.

This code base has gone through several iterations of development, and was
originally extracted from [Travis
Worker](https://github.com/travis-ci/worker), before taking its current
form.

## Running test suites

Run

```
bundle exec rake
```

## Use as addon for CLI

You can set travis-build up as a plugin for the [command line client](https://github.com/travis-ci/travis.rb):

    ln -s PATH_TO_TRAVIS_BUILD ~/.travis/travis-build
    gem install bundler
    bundle install --gemfile ~/.travis/travis-build/Gemfile
    bundler binstubs travis

You will now be able to run the `compile` command, which produces
the bash script that runs the specified job, except that the secure environment
variables are not defined, and that the build matrix expansion is not considered.

    ~/.travis/travis-build/bin/travis compile

### _Important_

The resulting script contains commands that make changes to the system on which it is executed
(e.g., edit `/etc/resolv.conf`, install software).
Some require `sudo` privileges and they are not easily undone.

It is highly recommended that you run this on a virtual machine.

### Invocation

The command can be invoked in 3 ways:

1. Without an argument, it produces the bash script for the local `.travis.yml` without considering `env` and `matrix` values
(`travis-build` is unable to expand these keys correctly).

    `$ ~/.travis/travis-build/bin/travis compile`

1. With a single integer, it produces the script for the given build
(or the first job of that build matrix).

    `$ ~/.travis/travis-build/bin/travis compile 8`

1. With an argument of the form `M.N`, it produces the bash script for the job `M.N`.

    `$ ~/.travis/travis-build/bin/travis compile 351.2`

The resultant script can be used on a (virtual) machine that closely mimics Travis CI's build
environment to aid you in debugging the build failures.

## Raw CLI script

In addition to the travis CLI plugin you can also run the standalone CLI script:

    $ bundle exec script/compile < payload.json > build.sh

## Docker container

If you want to run travis-build locally on your machine (e.g. to interact with [worker](https://github.com/travis-ci/worker)), you can also run it as a docker container with docker-compose:

    $ docker-compose up

## License & copyright information

See LICENSE file.

Copyright (c) 2011-2016 [Travis CI development
team](https://github.com/travis-ci).
