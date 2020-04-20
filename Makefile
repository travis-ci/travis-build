SHELL := bash

VERSION_VALUE ?= $(shell git rev-parse --short HEAD 2>/dev/null)
DOCKER_IMAGE_REPO ?= travisci/travis-build
DOCKER_DEST ?= $(DOCKER_IMAGE_REPO):$(VERSION_VALUE)
QUAY ?= quay.io
QUAY_IMAGE ?= $(QUAY)/$(DOCKER_IMAGE_REPO)

ifdef $$QUAY_ROBOT_HANDLE
	QUAY_ROBOT_HANDLE := $$QUAY_ROBOT_HANDLE
endif

ifdef $$QUAY_ROBOT_TOKEN
	QUAY_ROBOT_TOKEN := $$QUAY_ROBOT_TOKEN
endif

ifndef $$TRAVIS_BRANCH
	TRAVIS_BRANCH ?= $(shell git rev-parse --abbrev-ref HEAD)
endif
BRANCH = $(shell echo "$(TRAVIS_BRANCH)" | sed 's/\//_/')

ifdef $$TRAVIS_PULL_REQUEST
	TRAVIS_PULL_REQUEST := $$TRAVIS_PULL_REQUEST
endif

ifndef $$PLATFORM_TYPE
	PLATFORM_TYPE ?= $$PLATFORM_TYPE
endif

ifndef $$RUBYENCODER_PROJECT_ID
	RUBYENCODER_PROJECT_ID ?= $$RUBYENCODER_PROJECT_ID
endif

ifndef $$RUBYENCODER_PROJECT_KEY
	RUBYENCODER_PROJECT_KEY ?= $$RUBYENCODER_PROJECT_KEY
endif

ifeq ($(PLATFORM_TYPE), enterprise)

  ifeq ($(RUBYENCODER_PROJECT_ID),)
	$(error RUBYENCODER_PROJECT_ID not set correctly.)
  endif

  ifeq ($(RUBYENCODER_PROJECT_KEY),)
	$(error RUBYENCODER_PROJECT_KEY not set correctly.)
  endif

  BUILD_ARGUMENTS = --build-arg RUBYENCODER_PROJECT_ID="$(RUBYENCODER_PROJECT_ID)" --build-arg RUBYENCODER_PROJECT_KEY="$(RUBYENCODER_PROJECT_KEY)" --build-arg SSH_KEY="$$(cat ~/.ssh/id_rsa)"
else
  PLATFORM_TYPE = hosted
  BUILD_ARGUMENTS =
endif

DOCKER ?= docker

.PHONY: docker-build
docker-build:
	DOCKER_BUILDKIT=1 $(DOCKER) build --progress=plain --build-arg PLATFORM_TYPE="$(PLATFORM_TYPE)" $(BUILD_ARGUMENTS) -t $(DOCKER_DEST) .

.PHONY: docker-login
docker-login:
	$(DOCKER) login -u=$(QUAY_ROBOT_HANDLE) -p=$(QUAY_ROBOT_TOKEN) $(QUAY)

.PHONY: docker-push-latest-master
docker-push-latest-master:
	$(DOCKER) tag $(DOCKER_DEST) $(QUAY_IMAGE):$(VERSION_VALUE)
	$(DOCKER) push $(QUAY_IMAGE):$(VERSION_VALUE)
	$(DOCKER) tag $(DOCKER_DEST) $(QUAY_IMAGE):latest
	$(DOCKER) push $(QUAY_IMAGE):latest

.PHONY: docker-push-branch
docker-push-branch:
	$(DOCKER) tag $(DOCKER_DEST) $(QUAY_IMAGE):$(VERSION_VALUE)-$(BRANCH)
	$(DOCKER) push $(QUAY_IMAGE):$(VERSION_VALUE)-$(BRANCH)

.PHONY: ship
ship: docker-build docker-login

ifeq ($(BRANCH),master)
ifeq ($(TRAVIS_PULL_REQUEST),false)
ship: docker-push-latest-master
endif
else
ship: docker-push-branch
endif
