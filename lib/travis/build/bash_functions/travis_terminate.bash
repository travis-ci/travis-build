#!/bin/bash

travis_terminate() {
  set +e
  [[ "${TRAVIS_FILTERED}" == redirect_io && -e /dev/fd/9 ]] &&
    sync &&
    command exec 1>&9 2>&9 9>&- &&
    sync
  pgrep -u "${USER}" | grep -v -w "${$}" >"${TRAVIS_TMPDIR}/pids_after"
  awk 'NR==FNR{a[$1]++;next};!($1 in a)' "${TRAVIS_TMPDIR}"/pids_{before,after} |
    xargs kill &>/dev/null || true
  pkill -9 -P "${$}" &>/dev/null || true
  exit "${1}"
}
