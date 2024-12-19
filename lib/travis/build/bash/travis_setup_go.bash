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

  # shellcheck source=/dev/null

  travis_cmd "export GOPATH=\"${TRAVIS_HOME}/gopath\"" --echo
  travis_cmd "export PATH=\"${TRAVIS_HOME}/gopath/bin:${PATH}\"" --echo
  travis_cmd "export GO111MODULE=\"${GO111MODULE}\"" --echo

  go install "golang.org/dl/go${go_version}@latest"
  "go${go_version}" download
  sudo ln -s "${TRAVIS_HOME}/gopath/bin/go${go_version}" "${TRAVIS_HOME}/gopath/bin/go"
  travis_cmd "export GOROOT=$(go"${go_version}" env GOROOT)" --echo
  travis_cmd "export PATH=${GOROOT}/bin:${PATH}" --echo
}
