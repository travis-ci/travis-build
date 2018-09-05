#!/bin/bash

travis_vers2int() {
  local args
  read -r -a args <<<"$(echo "${1}" | tr '.' ' ')"
  printf '1%03d%03d%03d%03d' "${args[@]}"
}
