FROM ruby:2.5.8 as builder

ARG GITHUB_OAUTH_TOKEN=notset

RUN gem update --silent --system 3.3.26

WORKDIR /app

COPY . .

RUN git describe --always --dirty --tags | tee VERSION
RUN git rev-parse --short HEAD | tee BUILD_SLUG_COMMIT
RUN rm -rf .git

RUN bundle install --frozen --deployment --without='development test' --clean

RUN bundle exec rake assets:precompile GITHUB_OAUTH_TOKEN=$GITHUB_OAUTH_TOKEN
RUN tar -cjf public.tar.bz2 public && rm -rf public


FROM ruby:2.5.8-slim

LABEL maintainer Travis CI GmbH <support+travis-build-docker-images@travis-ci.com>
<<<<<<< HEAD

RUN ( \
   apt-get update ; \
   # update to deb 10.8
   apt-get upgrade -y ; \
   rm -rf /var/lib/apt/lists/* \
)

WORKDIR /app
=======
>>>>>>> 39a28723 (Fix build)

ENV TRAVIS_BUILD_DUMP_BACKTRACE true
ENV PORT 4000

RUN gem update --silent --system 3.3.26

WORKDIR /app

COPY --from=builder /app /app
COPY --from=builder /usr/local/bundle/config /usr/local/bundle/config

HEALTHCHECK --interval=5s CMD script/healthcheck

EXPOSE $PORT/tcp

CMD ["script/server"]
