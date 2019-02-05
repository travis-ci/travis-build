travis_setup_go() {
  local go_version="${TRAVIS_GO_VERSION:-${1}}"
  local go_import_path="${2}"

  if [[ ! "${go_import_path}" ]]; then
    echo 'Missing go_import_path positional argument' >&2
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

  # NOTE: $GOPATH is a plural ":"-separated var a la $PATH.  We export
  # only a single path here, but users who want to treat $GOPATH as
  # singular *should* probably use "${GOPATH%%:*}" to take the first
  # entry.
  travis_cmd export\ GOPATH="${TRAVIS_HOME}/gopath" --echo
  travis_cmd export\ PATH="${TRAVIS_HOME}/gopath/bin:$PATH" --echo

  if __travis_go_supports_modules; then
    travis_cmd export\ GO111MODULE=on --echo
    return 0
  fi

  mkdir -p "${TRAVIS_HOME}/gopath/src/${go_import_path}"
  tar -Pczf "${TRAVIS_TMPDIR}/src_archive.tar.gz" -C "${TRAVIS_BUILD_DIR}" . &&
    tar -Pxzf "${TRAVIS_TMPDIR}/src_archive.tar.gz" -C "${TRAVIS_HOME}/gopath/src/${go_import_path}"

  export TRAVIS_BUILD_DIR="${TRAVIS_HOME}/gopath/src/${go_import_path}"
  travis_cmd cd\ "${TRAVIS_HOME}/gopath/src/${go_import_path}" --assert

  # Defer setting up cache until we have changed directories, so that
  # cache.directories can be properly resolved relative to the directory
  # in which the user-controlled portion of the build starts
  # See https://github.com/travis-ci/travis-ci/issues/3055
  local _old_remote
  _old_remote="$(git config --get remote.origin.url)"
  git config remote.origin.url "${_old_remote%.git}"
}
