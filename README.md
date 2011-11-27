# What is travis-build

travis-build is a library that travis-ci.org workers use to clone repositories, manage dependencies,
run test suites and perform other CI build life cycle operations. It was originally extracted from
[https://github.com/travis-ci/travis-worker](travis-worker).


## Running test suites

On JRuby (currently 1.8 mode):

    bundle exec rspec spec
    bundle exec cucumber


## License & copyright information ##

See LICENSE file.

Copyright (c) 2011 [Travis CI development team](https://github.com/travis-ci).
