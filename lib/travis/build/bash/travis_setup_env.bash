# shellcheck disable=SC1117 disable=SC2034

travis_setup_env() {
  declare -rx ANSI_RED="\033[31;1m"
  declare -rx ANSI_GREEN="\033[32;1m"
  declare -rx ANSI_YELLOW="\033[33;1m"
  declare -rx ANSI_RESET="\033[0m"
  declare -rx ANSI_CLEAR="\033[0K"

  export DEBIAN_FRONTEND=noninteractive

  if [ "${TERM}" = dumb ]; then
    unset TERM
  fi
  : "${SHELL:=/bin/bash}"
  : "${TERM:=xterm}"
  : "${USER:=travis}"
  export SHELL
  export TERM
  export USER

  case $(uname | tr '[:upper:]' '[:lower:]') in
  linux*) TRAVIS_OS_NAME=linux ;;
  darwin*) TRAVIS_OS_NAME=osx ;;
  *) TRAVIS_OS_NAME=notset ;;
  esac
  export TRAVIS_OS_NAME; _RO+=(TRAVIS_OS_NAME)

  export TRAVIS_DIST=notset; _RO+=(TRAVIS_DIST)
  export TRAVIS_INIT=notset; _RO+=(TRAVIS_INIT)
  export TRAVIS_ARCH="$(uname -m)"; _RO+=(TRAVIS_ARCH)
  if [[ "${TRAVIS_ARCH}" == x86_64 ]]; then
    TRAVIS_ARCH='amd64'
  fi

  if [[ "${TRAVIS_OS_NAME}" == linux ]]; then
    TRAVIS_DIST="$(lsb_release -sc 2>/dev/null || echo notset)"
    if command -v systemctl >/dev/null 2>&1; then
      TRAVIS_INIT=systemd
    else
      TRAVIS_INIT=upstart
    fi
  fi

  export TRAVIS_TEST_RESULT=
  export TRAVIS_CMD=

  TRAVIS_TMPDIR="$(mktemp -d 2>/dev/null || mktemp -d -t 'travis_tmp')"
  export TRAVIS_TMPDIR; _RO+=(TRAVIS_TMPDIR)

  export TRAVIS_INFRA=unknown; _RO+=(TRAVIS_INFRA)
  if [[ "${TRAVIS_ENABLE_INFRA_DETECTION}" == true ]]; then
    TRAVIS_INFRA="$(travis_whereami | awk -F= '/^infra/ { print $2 }')"
  fi

  if command -v pgrep &>/dev/null; then
    pgrep -u "${USER}" 2>/dev/null |
      grep -v -w "${$}" >"${TRAVIS_TMPDIR}/pids_before"
  fi
}
