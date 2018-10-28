FROM ruby:2.5.3

LABEL maintainer Travis CI GmbH <support+travis-app-docker-images@travis-ci.com>

WORKDIR /usr/src/app

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

COPY Gemfile      /usr/src/app
COPY Gemfile.lock /usr/src/app

RUN bundler install --verbose --retry=3

COPY . /usr/src/app

ARG GITHUB_OAUTH_TOKEN=notset
ENV TRAVIS_BUILD_DUMP_BACKTRACE true
ENV PORT 8080

RUN bundle exec rake assets:precompile GITHUB_OAUTH_TOKEN=$GITHUB_OAUTH_TOKEN

CMD ./script/server

CMD ["script/server"]
