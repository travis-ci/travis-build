FROM ruby:2.3-onbuild
LABEL maintainer Travis CI GmbH <support+travis-build-docker-image@travis-ci.org>

CMD ["./docker-cmd.sh"]
