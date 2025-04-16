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

  if ! command -v go &>/dev/null; then
    echo "Go is not installed. Installing..."
    travis_cmd "choco install golang --version=${go_version} -y" --echo
    travis_cmd "export GOROOT=\"C:\\Program Files\\Go\"" --echo
    travis_cmd "export PATH=\"/c/Program Files/Go/bin:$PATH\"" --echo
    travis_cmd "export GO111MODULE=\"${GO111MODULE}\"" --echo
  else
    echo "Go is already installed. Setting up specific version..."
    travis_cmd "export GOPATH=\"${TRAVIS_HOME}/gopath\"" --echo
    travis_cmd "export PATH=\"${TRAVIS_HOME}/gopath/bin:${PATH}\"" --echo
    travis_cmd "export GO111MODULE=\"${GO111MODULE}\"" --echo
    travis_cmd "go install \"golang.org/dl/go${go_version}@latest\"" --echo
    travis_cmd "\"go${go_version}\" download" --echo
    travis_cmd "sudo ln -s \"${TRAVIS_HOME}/gopath/bin/go${go_version}\" \"${TRAVIS_HOME}/gopath/bin/go\"" --echo
    travis_cmd "export GOROOT=\$(go${go_version} env GOROOT)" --echo
    travis_cmd "export PATH=\${GOROOT}/bin:\${PATH}" --echo
  fi

  mkdir -p "$(dirname "${GOPATH}/src/${go_import_path}")"
  ln -s "${TRAVIS_BUILD_DIR}" "$GOPATH/src/${go_import_path}"
}
