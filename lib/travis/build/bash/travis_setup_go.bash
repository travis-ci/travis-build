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

https://go.dev/dl/go1.23.2.linux-arm64.tar.gz

  # Check if Go is installed
  if ! command -v go &> /dev/null; then
    echo "Go is not installed. Installing default Go..."
    wget https://go.dev/dl/go1.23.2.linux-${TRAVIS_CPU_ARCH}.tar.gz
    sudo tar -C /usr/local -xzf go1.23.2.linux-${TRAVIS_CPU_ARCH}.tar.gz
    travis_cmd "PATH=${PATH}:/usr/local/go/bin"
  else
    echo "Go is already installed correctly. Moving on..."
  fi

  travis_cmd "export GOPATH=\"${TRAVIS_HOME}/gopath\""
  travis_cmd "export PATH=\"${TRAVIS_HOME}/gopath/bin:${PATH}\""
  travis_cmd "export GO111MODULE=\"${GO111MODULE}\"" 

  go install "golang.org/dl/go${go_version}@latest"
  "go${go_version}" download
  sudo ln -s "${TRAVIS_HOME}/gopath/bin/go${go_version}" "${TRAVIS_HOME}/gopath/bin/go"
  travis_cmd "export GOROOT=$(go"${go_version}" env GOROOT)"
  travis_cmd "export PATH=${GOROOT}/bin:${PATH}"
}
