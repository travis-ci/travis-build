FROM ruby:2.5.3 as builder
WORKDIR /usr/src/app

ARG GITHUB_OAUTH_TOKEN=notset

RUN bundle config --global frozen 1

COPY . .

RUN bundle install
RUN bundle exec rake assets:precompile GITHUB_OAUTH_TOKEN=$GITHUB_OAUTH_TOKEN

FROM ruby:2.5.3-slim
LABEL maintainer Travis CI GmbH <support+travis-app-docker-images@travis-ci.com>
WORKDIR /usr/src/app

ENV TRAVIS_BUILD_DUMP_BACKTRACE true
ENV PORT 4000

COPY --from=builder /usr/src/app /usr/src/app
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /root/.bundle /root/.bundle

CMD ["script/server"]
