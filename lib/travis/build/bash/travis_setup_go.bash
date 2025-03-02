travis_setup_go() {
  local go_version="${TRAVIS_GO_VERSION:-${1}}"
  local go_import_path="${TRAVIS_GO_IMPORT_PATH:-${2}}"

  if [[ -z "${go_version}" ]]; then
    echo 'Missing TRAVIS_GO_VERSION' >&2
    return 86
  fi

  if [[ -z "${go_import_path}" ]]; then
    echo 'Missing TRAVIS_GO_IMPORT_PATH' >&2
    return 86
  fi

  export GOPATH="${TRAVIS_HOME}/gopath"
  echo "GOPATH set to: $GOPATH"

  export PATH="${TRAVIS_HOME}/gopath/bin:${PATH}"
  echo "Updated PATH: $PATH"

  export GO111MODULE="on"
  echo "GO111MODULE set to: $GO111MODULE"

  if [[ "$TRAVIS_OS_NAME" == "windows" ]]; then
    echo "Detected Windows environment. Installing Go via Chocolatey..."
    choco install golang --version="${go_version}" -y
    export PATH="/c/Go/bin:${PATH}"
    echo "Windows PATH updated: $PATH"

    # Ensure Go is installed
    if ! command -v go &>/dev/null; then
      echo "Go installation failed! Exiting..."
      exit 1
    fi
  else
    echo "Detected Linux/macOS environment. Installing Go..."
    go install "golang.org/dl/go${go_version}@latest"
    "go${go_version}" download

    # Use sudo only if available
    if command -v sudo &>/dev/null; then
      sudo ln -s "${TRAVIS_HOME}/gopath/bin/go${go_version}" "${TRAVIS_HOME}/gopath/bin/go"
    else
      ln -s "${TRAVIS_HOME}/gopath/bin/go${go_version}" "${TRAVIS_HOME}/gopath/bin/go"
    fi

    # Ensure Go exists before setting GOROOT
    if command -v "go${go_version}" &>/dev/null; then
      export GOROOT=$("go${go_version}" env GOROOT)
      echo "GOROOT set to: $GOROOT"
    else
      echo "ERROR: go${go_version} command not found!"
      return 1
    fi
  fi

  export PATH="${GOROOT}/bin:${PATH}"
  echo "Final PATH: $PATH"

  mkdir -p "$(dirname "${GOPATH}/src/${go_import_path}")"
  ln -s "${TRAVIS_BUILD_DIR}" "$GOPATH/src/${go_import_path}"
}
