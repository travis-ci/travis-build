#!/usr/bin/env bash

function travis_artifacts_install() {
  local os=$(uname | tr '[:upper:]' '[:lower:]')
  local arch=$(uname -m)
  [[ $arch == x86_64 ]] && arch=amd64
  local source="https://s3.amazonaws.com/travis-ci-gmbh/artifacts/stable/build/$os/$arch/artifacts"
  local target=$HOME/bin/artifacts

  mkdir -p $(dirname $target)
  curl -sL -o $target $source
  chmod +x $target
  PATH="$(dirname $target):$PATH" artifacts -v
}
