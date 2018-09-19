FROM ruby:2.5.1
LABEL maintainer Travis CI GmbH <support+travis-app-docker-images@travis-ci.com>
WORKDIR /usr/src/app
COPY . .
ARG GITHUB_OAUTH_TOKEN=notset
RUN bundle config --global frozen 1
RUN bundle install
RUN bundle exec rake assets:precompile GITHUB_OAUTH_TOKEN=$GITHUB_OAUTH_TOKEN
CMD env TRAVIS_BUILD_DUMP_BACKTRACE=true bundle exec je puma -I lib -p ${PORT:-4000} -t ${PUMA_MIN_THREADS:-8}:${PUMA_MAX_THREADS:-12} -w ${PUMA_WORKERS:-2}
