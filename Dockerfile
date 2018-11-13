FROM ruby:2.5.3 as builder
WORKDIR /usr/src/app

ARG GITHUB_OAUTH_TOKEN=notset

COPY . .

RUN git describe --always --dirty --tags | tee VERSION
RUN bundle install --frozen --deployment --without='development test' --clean
RUN bundle exec rake assets:precompile GITHUB_OAUTH_TOKEN=$GITHUB_OAUTH_TOKEN
RUN tar -cjf public.tar.bz2 public && rm -rf public

FROM ruby:2.5.3-slim
LABEL maintainer Travis CI GmbH <support+travis-app-docker-images@travis-ci.com>
WORKDIR /usr/src/app

ENV TRAVIS_BUILD_DUMP_BACKTRACE true
ENV PORT 4000

COPY --from=builder /usr/src/app /usr/src/app
COPY --from=builder /usr/local/bundle/config /usr/local/bundle/config
RUN rm -rf .git

HEALTHCHECK --interval=5s CMD script/healthcheck
EXPOSE 4000/tcp
CMD ["script/server"]
