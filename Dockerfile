FROM ruby:2.5.3
LABEL maintainer Travis CI GmbH <support+travis-app-docker-images@travis-ci.com>
WORKDIR /usr/src/app

ARG GITHUB_OAUTH_TOKEN=notset
ENV TRAVIS_BUILD_DUMP_BACKTRACE true
ENV PORT 4000

COPY . .
RUN bundle config --global frozen 1
RUN bundle install
RUN bundle exec rake assets:precompile GITHUB_OAUTH_TOKEN=$GITHUB_OAUTH_TOKEN

CMD ["script/server"]
