# Travis Build [![Build Status](https://travis-ci.org/travis-ci/travis-build.svg?branch=master)](https://travis-ci.org/travis-ci/travis-build)

Travis Build exposes an API that [Travis
Workers](https://github.com/travis-ci/worker) and [Job
Board](https://github.com/travis-ci/job-board) use to generate a bash script
which is then copied to the job execution environment and executed, with the
resulting output streamed back to Travis.

This code base has gone through several iterations of development, and was
originally extracted from [the legacy Travis
Worker](https://github.com/travis-ci/travis-worker), before taking its current
form.

## Running test suites

For basic testing, run:

```sh-session
$ bundle exec rake clean assets:precompile
$ bundle exec rspec spec
```

More comprehensive tests are also possible. See `.travis.yml` for more
information.

## Docker container

If you want to run travis-build locally on your machine (e.g. to interact with
[worker](https://github.com/travis-ci/worker)), you can also run it as a docker
container with docker-compose:

First, build the image:

``` bash
docker-compose build web
```

Second, run the image:

```bash
docker-compose run web
```

You may wish to run with a different setup for local development.
The following shows running `travis-build` in the `development`
environment, forwarding the Docker image's port 4000 to the host's
port 4000:

```bash
docker-compose run -e RACK_ENV=development -p 4000:4000 web
```

See [`docker-compose` documentation](https://docs.docker.com/compose/reference/run/)
for more information.

## Testing script generation

Once you have the Docker container running as explained in the previous section,
it is possible to test `travis-build`'s script generating capability with the
`compile` script.

### Using `compile`

On its most basic level, `compile` constructs an appropriate JSON payload and
issues an HTTP `POST` request to `/script`, which is exactly how `travis-build`
does its job internally.

To create the payload, the script requires a job (not build) id to fetch from
the API server; for example:

    ./compile -p 4000 451073131

By default, the script fetches data from the .org API endpoint (https://api.travis-ci.org),
and sends the `POST` request to `localhost`'s port 80.
In the above example, we override the port, since the Docker container publishes
port 4000 (as indicated in the previous section).

### Deployment data

Since deployment configuration is most often sensitive, and is not exposed by
the API server, the returned script does not have any deployment-related
information.

To fill in the deployment data, `script` takes the `--deploy` flag.
If deployment configuration is stored in a JSON or YAML file, you can specify:

    ./compile -p 4000 --deploy=deploy.json 451073131

It is also possible to feed the JSON data via STDIN. This is useful if you want
to read the YAML configuration from GitHub:

    $ curl -sSf -L https://raw.githubusercontent.com/REPO/OWNER/master/.travis.yml | ruby -r yaml -r json -e 'puts YAML.load($stdin).to_json' | jq .deploy | ./compile -p 4000 --deploy -

Here, we read the configuration from https://raw.githubusercontent.com/REPO/OWNER/master/.travis.yml,
converts it to JSON, then pick out the `deploy` definition at the top level with
[jq](https://stedolan.github.io/jq/).


### _Important_

The resulting script contains commands that make changes to the system on which
it is executed (e.g., edit `/etc/resolv.conf`, install software).  Some require
`sudo` privileges and they are not easily undone.

It is highly recommended that you run this in a container or other virtualized
environment.

The generated script can be used in a container or virtualized environment that
closely mimics Travis CI's build environment to aid you in debugging the build
failures.  Instructions for running such a container are available
[in the Travis CI docs](https://docs.travis-ci.com/user/common-build-problems/#running-a-container-based-docker-image-locally).

## License & copyright information

See [LICENSE](./LICENSE) file.

Copyright (c) 2011-2018 [Travis CI development
team](https://github.com/travis-ci).
