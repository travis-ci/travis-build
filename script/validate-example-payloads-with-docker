#!/usr/bin/env bash
set -o errexit
set -o pipefail

main() {
  # shellcheck disable=SC2154
  if [[ ! "${GITHUB_OAUTH_TOKEN}" && "${no_scope_token}" ]]; then
    echo "----> Using no_scope_token for GitHub OAuth"
    GITHUB_OAUTH_TOKEN="${no_scope_token}"
  fi

  [[ "${GITHUB_OAUTH_TOKEN}" ]] || {
    echo Missing GITHUB_OAUTH_TOKEN
    exit 86
  }

  if [[ "${GITHUB_OAUTH_TOKEN}" == notset ]]; then
    echo Refusing to use GITHUB_OAUTH_TOKEN=notset
    exit 86
  fi

  export GITHUB_OAUTH_TOKEN

  local top
  top="$(git rev-parse --show-toplevel)"
  cd "${top}"

  unset DOCKER_CERT_PATH
  unset DOCKER_HOST
  unset DOCKER_TLS
  unset DOCKER_TLS_VERIFY

  echo "----> Building web container"
  docker-compose build web
  local cpid

  echo "----> Running web container on port 4000"
  docker-compose run -e DISABLE_RERUN=1 -e RACK_ENV=development -p 4000:4000 web &
  cpid="${!}"

  local wait_times=0
  while ! curl -sf localhost:4000/uptime &>/dev/null; do
    if [[ "${wait_times}" -gt 6 ]]; then
      echo '----> Timeout waiting for container to be up' >&2
      exit 1
    fi
    echo '----> Still waiting for container to be up' >&2
    sleep 5
    wait_times=$((wait_times + 1))
  done

  local e=0
  for f in example_payloads/*.json; do
    local bn="${f##*/}"
    local script_out="${top}/tmp/example_payload-${bn}.bash"
    echo "----> Requesting payload for ${bn}"
    if ! curl -sf -X POST -o "${script_out}" -d "@${f}" localhost:4000/script; then
      e=$((e + 1))
    fi

    echo "----> Checking syntax of ${script_out}"
    if ! shfmt "${script_out}" &>/dev/null; then
      e=$((e + 1))
    fi
  done

  [[ "${e}" -eq 0 ]]

  kill "${cpid}" || true
}

main "${@}"
