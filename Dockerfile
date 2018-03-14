FROM ruby:2.3.4 AS base
LABEL maintainer Travis CI GmbH <support+travis-app-docker-images@travis-ci.com>
# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1
WORKDIR /usr/src/app
COPY . .
RUN bundle install

FROM base
ARG GITHUB_OAUTH_TOKEN=notset
RUN bundle exec rake assets:precompile GITHUB_OAUTH_TOKEN=$GITHUB_OAUTH_TOKEN
CMD bundle exec je puma -I lib -p ${PORT:-4000} -t ${PUMA_MIN_THREADS:-8}:${PUMA_MAX_THREADS:-12} -w ${PUMA_WORKERS:-2}
