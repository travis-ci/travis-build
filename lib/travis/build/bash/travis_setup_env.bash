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
  linux)
    TRAVIS_OS_NAME=linux
    ;;
  darwin)
    TRAVIS_OS_NAME=osx
    ;;
  *)
    TRAVIS_OS_NAME=notset
    ;;
  esac

  TRAVIS_DIST=notset
  TRAVIS_INIT=notset
  TRAVIS_ARCH="$(uname -m)"
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

  TRAVIS_INFRA=unknown
  if [[ "${TRAVIS_ENABLE_INFRA_DETECTION}" == true ]]; then
    TRAVIS_INFRA="$(travis_whereami | awk -F= '/^infra/ { print $2 }')"
  fi

  if command -v pgrep &>/dev/null; then
    pgrep -u "${USER}" 2>/dev/null |
      grep -v -w "${$}" >"${TRAVIS_TMPDIR}/pids_before"
  fi

  _RO+=(TRAVIS_ARCH TRAVIS_DIST TRAVIS_DIST TRAVIS_INFRA TRAVIS_INIT)
  _RO+=(TRAVIS_OS_NAME TRAVIS_TMPDIR)
}
