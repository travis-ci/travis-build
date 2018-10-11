# shellcheck disable=SC1117

travis_setup_env() {
  export ANSI_RED="\033[31;1m"
  export ANSI_GREEN="\033[32;1m"
  export ANSI_YELLOW="\033[33;1m"
  export ANSI_RESET="\033[0m"
  export ANSI_CLEAR="\033[0K"

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
  linux*)
    export TRAVIS_OS_NAME=linux
    ;;
  darwin*)
    export TRAVIS_OS_NAME=osx
    ;;
  msys*)
    export TRAVIS_OS_NAME=windows
    ;;
  *)
    export TRAVIS_OS_NAME=notset
    ;;
  esac

  export TRAVIS_DIST=notset
  export TRAVIS_INIT=notset
  TRAVIS_ARCH="$(uname -m)"
  if [[ "${TRAVIS_ARCH}" == x86_64 ]]; then
    TRAVIS_ARCH='amd64'
  fi
  export TRAVIS_ARCH

  if [[ "${TRAVIS_OS_NAME}" == linux ]]; then
    TRAVIS_DIST="$(lsb_release -sc 2>/dev/null || echo notset)"
    export TRAVIS_DIST
    if command -v systemctl >/dev/null 2>&1; then
      export TRAVIS_INIT=systemd
    else
      export TRAVIS_INIT=upstart
    fi
  fi

  export TRAVIS_TEST_RESULT=
  export TRAVIS_CMD=

  TRAVIS_TMPDIR="$(mktemp -d 2>/dev/null || mktemp -d -t 'travis_tmp')"
  mkdir -p "${TRAVIS_TMPDIR}"
  export TRAVIS_TMPDIR

  TRAVIS_INFRA=unknown
  if [[ "${TRAVIS_ENABLE_INFRA_DETECTION}" == true ]]; then
    TRAVIS_INFRA="$(travis_whereami | awk -F= '/^infra/ { print $2 }')"
  fi
  export TRAVIS_INFRA

  if command -v pgrep &>/dev/null; then
    pgrep -u "${USER}" 2>/dev/null |
      grep -v -w "${$}" >"${TRAVIS_TMPDIR}/pids_before" || true
  fi
}
