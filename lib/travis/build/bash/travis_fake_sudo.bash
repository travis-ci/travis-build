#!/bin/bash

main() {
  if [[ -f "${HOME}/.sudo-run" ]]; then
    exit 1
  fi

  OPTIND=1
  while getopts "v" opt; do
    case "${opt}" in
    v)
      QUIET=1
      ;;
    *)
      :
      ;;
    esac
  done

  shift "$((OPTIND - 1))"

  if [[ "${QUIET}" != 1 ]]; then
    echo -e "\\033[33;1mThis job is running on container-based infrastructure, which does not allow use of 'sudo', setuid, and setgid executables.\\033[0m
\\033[33;1mIf you require sudo, add 'sudo: required' to your .travis.yml\\033[0m
"
  fi

  touch "${HOME}/.sudo-run"
  exit 1
}

main "${@}"
