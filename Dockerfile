FROM ubuntu:latest
#FROM armv7/armhf-ubuntu
#FROM ppc64le/ubuntu:latest

LABEL maintainer Travis CI GmbH <support+travis-app-docker-images@travis-ci.com>

RUN apt-get -qq update && apt-get -qq upgrade -y && apt-get -qq install apt-utils

RUN apt-get -qq install -y wget git ruby ruby-dev build-essential clang libffi-dev

RUN gem install ffi

RUN gem install bundler

RUN bundle config --global frozen 1

RUN mkdir -p /usr/src/app

WORKDIR /usr/src/app

COPY Gemfile      /usr/src/app

COPY Gemfile.lock /usr/src/app

RUN bundle install

COPY . /usr/src/app

CMD bundle exec je puma -I lib -p ${PORT:-4000} -t ${PUMA_MIN_THREADS:-8}:${PUMA_MAX_THREADS:-12} -w ${PUMA_WORKERS:-2}
