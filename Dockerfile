FROM ruby:2.3.4-onbuild

LABEL maintainer Travis CI GmbH <support+travis-build-docker-image@travis-ci.com>

COPY Gemfile      /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock

RUN bundle install

COPY . /app

CMD bundle exec je puma -I lib -p ${PORT:-4000} -t ${PUMA_MIN_THREADS:-8}:${PUMA_MAX_THREADS:-12} -w ${PUMA_WORKERS:-2}
