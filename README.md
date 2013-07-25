# Travis Build

Travis Build is a library that [Travis
Workers](https://github.com/travis-ci/travis-worker) use to generate a shell
based build script which is then uploaded to the VMs using SSH and executed,
with the resulting output streamed back to Travis.

This code base has gone through several iterations of development, and was
originally extracted from [Travis
Worker](https://github.com/travis-ci/travis-worker), before taking it's current
form.

The `examples/` directory contains several examples on what build scripts look
like for different projects. Note that they are not intended to be runnable,
they're just meant to serve as an example of the order the commands are run and
what commands are run. The examples are generated when the test suite is run.

## Running test suites

    bundle exec rspec spec

## License & copyright information

See LICENSE file.

Copyright (c) 2011-2013 [Travis CI development
team](https://github.com/travis-ci).
