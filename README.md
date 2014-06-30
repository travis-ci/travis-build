# Travis Build [![Build Status](https://travis-ci.org/travis-ci/travis-build.png?branch=master)](https://travis-ci.org/travis-ci/travis-build)

Travis Build is a library that [Travis
Workers](https://github.com/travis-ci/travis-worker) use to generate a shell
based build script which is then uploaded to the VMs using SSH and executed,
with the resulting output streamed back to Travis.

This code base has gone through several iterations of development, and was
originally extracted from [Travis
Worker](https://github.com/travis-ci/travis-worker), before taking it's current
form.

## Running test suites

### Note
Currently, the specs actually runs generated build scripts. We recommend
running them inside a virtual machine.

    bundle exec rspec spec

## Use as addon for CLI

You can set travis-build up as a plugin for the [command line client](https://github.com/travis-ci/travis):

    ln -s PATH_TO_TRAVIS_BUILD ~/.travis/travis-build

Now you can run one or many stages locally (defaults to script stage):

    $ travis run
    ... executes test ...
    $ travis run install
    ... installs dependencies ...
    $ travis run install script
    ... installs dependencies ...
    ... executes test ...

## License & copyright information

See LICENSE file.

Copyright (c) 2011-2013 [Travis CI development
team](https://github.com/travis-ci).
