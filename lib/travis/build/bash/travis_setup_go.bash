travis_setup_go() {
  local go_version="${TRAVIS_GO_VERSION:-${1}}"
  local go_import_path="${TRAVIS_GO_IMPORT_PATH:-${2}}"

  if [[ ! "${go_version}" ]]; then
    echo 'Missing TRAVIS_GO_VERSION' >&2
    return 86
  fi

  if [[ ! "${go_import_path}" ]]; then
    echo 'Missing TRAVIS_GO_IMPORT_PATH' >&2
    return 86
  fi

  export GIMME_GO_VERSION="${go_version}"
  __travis_go_ensure_resolved

  local gimme_env="${TRAVIS_TMPDIR}/gimme.env"
  if ! gimme >"${gimme_env}"; then
    echo 'Failed to run gimme' >&2
    return 86
  fi

  tee -a "${TRAVIS_HOME}/.bashrc" <"${gimme_env}" &>/dev/null
  # shellcheck source=/dev/null
  source "${gimme_env}"

  travis_cmd "export GOPATH=\"${TRAVIS_HOME}/gopath\"" --echo
  travis_cmd "export PATH=\"${TRAVIS_HOME}/gopath/bin:${PATH}\"" --echo
  travis_cmd "export GO111MODULE=\"${GO111MODULE}\"" --echo

  mkdir -p "${TRAVIS_HOME}/gopath/src/${go_import_path}"
  tar -Pczf "${TRAVIS_TMPDIR}/src_archive.tar.gz" -C "${TRAVIS_BUILD_DIR}" . &&
    tar -Pxzf "${TRAVIS_TMPDIR}/src_archive.tar.gz" -C "${TRAVIS_HOME}/gopath/src/${go_import_path}"

  export TRAVIS_BUILD_DIR="${TRAVIS_HOME}/gopath/src/${go_import_path}"
  travis_cmd cd\ "${TRAVIS_HOME}/gopath/src/${go_import_path}" --assert

  local _old_remote
  _old_remote="$(git config --get remote.origin.url)"
  git config remote.origin.url "${_old_remote%.git}"
}
