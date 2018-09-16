#!/usr/bin/env bash
set -o errexit

main() {
  local top client_config_url
  top="$(git rev-parse --show-toplevel)"

  [[ "${DOCKER_CLIENT_CONFIG_URL}" ]] || {
    log "missing \${DOCKER_CLIENT_CONFIG_URL}"
    exit 0
  }

  client_config_url="$(base64 --decode <<<"${DOCKER_CLIENT_CONFIG_URL}")"

  local tmp_zip="${top}/tmp/docker-client-config.zip"
  mkdir -p "${top}/tmp"

  log 'fetching client config'
  curl -fsSL -o "${tmp_zip}" "${client_config_url}" >&2

  log "expanding ${tmp_zip}"
  unzip -d "${top}" "${tmp_zip}" >&2

  echo "export DOCKER_CERT_PATH='${top}/.docker';"
  echo "export DOCKER_TLS_VERIFY=1;"
  echo "export DOCKER_TLS=1;"
}

log() {
  printf "handle-docker-config: %s\\n" "${*}" >&2
}

main "${@}"
