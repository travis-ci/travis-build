# Defining platform type
ARG PLATFORM_TYPE=hosted

# Building the hosted base image
FROM ruby:2.5.3-slim as builder-hosted

RUN ( \
   apt-get update ; \
   apt-get install -y --no-install-recommends gettext-base git make g++ libpq-dev openssh-server \
   && rm -rf /var/lib/apt/lists/* \
)
RUN mkdir -p /app
COPY . /app

# Building the enterprise base image
FROM builder-hosted as builder-enterprise

ARG RUBYENCODER_PROJECT_ID
ARG RUBYENCODER_PROJECT_KEY
ARG SSH_KEY
RUN ( \
   if test $RUBYENCODER_PROJECT_ID; then \
     chmod +x /app/bin/te-encode && \
     ./app/bin/te-encode && \
     rm -rf /root/.ssh/id_rsa; \
   fi; \
)

FROM builder-${PLATFORM_TYPE}
LABEL maintainer Travis CI GmbH <support+travis-app-docker-images@travis-ci.com>

RUN ( \
   apt-get update ; \
   apt-get install -y --no-install-recommends gettext-base git make g++ libpq-dev \
   && rm -rf /var/lib/apt/lists/* \
)

RUN git describe --always --dirty --tags | tee VERSION
RUN git rev-parse --short HEAD | tee BUILD_SLUG_COMMIT
RUN rm -rf .git
RUN gem uninstall -v '>= 2' -i $(rvm gemdir)@global -ax bundler || true
RUN gem i bundler --no-document -v=1.17.3

WORKDIR /app

COPY Gemfile      /app
COPY Gemfile.lock /app

ARG GITHUB_OAUTH_TOKEN=notset
RUN bundle install --frozen --deployment --without='development test' --clean
RUN bundle exec rake assets:precompile GITHUB_OAUTH_TOKEN=$GITHUB_OAUTH_TOKEN
RUN tar -cjf public.tar.bz2 public && rm -rf public
ENV TRAVIS_BUILD_DUMP_BACKTRACE true
ENV PORT 4000

HEALTHCHECK --interval=5s CMD script/healthcheck
EXPOSE 4000/tcp
CMD ["script/server"]