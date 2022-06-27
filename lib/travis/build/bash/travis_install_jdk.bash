travis_install_jdk() {
  local url vendor version license jdk certlink
  jdk="$1"
  vendor="$2"
  version="$3"

  case "${TRAVIS_CPU_ARCH}" in
  "arm64" | "s390x" | "ppc64le" | "amd64")
    travis_install_jdk_package "$version"
    ;;
  *)
    travis_install_jdk_ext_provider "$jdk" "$vendor" "$version"
    ;;
  esac
}

travis_install_jdk_ext_provider() {
  local url vendor version license jdk certlink
  jdk="$1"
  vendor="$2"
  version="$3"
  if [[ "$vendor" == openjdk ]]; then
    license=GPL
  elif [[ "$vendor" == oracle ]]; then
    license=BCL
  fi
  mkdir -p ~/bin
  url="https://$TRAVIS_APP_HOST/files/install-jdk.sh"
  if ! travis_download "$url" ~/bin/install-jdk.sh; then
    url="https://raw.githubusercontent.com/sormuras/bach/releases/11/install-jdk.sh"
    travis_download "$url" ~/bin/install-jdk.sh || {
      echo "${ANSI_RED}Could not acquire install-jdk.sh. Stopping build.${ANSI_RESET}" >/dev/stderr
      travis_terminate 2
    }
  fi
  chmod +x ~/bin/install-jdk.sh
  travis_cmd "export JAVA_HOME=~/$jdk" --echo
  # shellcheck disable=SC2016
  travis_cmd 'export PATH="$JAVA_HOME/bin:$PATH"' --echo
  [[ "$TRAVIS_OS_NAME" == linux && "$vendor" == openjdk ]] && certlink=" --cacerts"
  # shellcheck disable=2088
  travis_cmd "~/bin/install-jdk.sh --target \"$JAVA_HOME\" --workspace \"$TRAVIS_HOME/.cache/install-jdk\" --feature \"$version\" --license \"$license\"$certlink" --echo --assert
}

travis_install_jdk_package() {

  local JAVA_VERSION
  JAVA_VERSION="$1"
  sudo apt-get update -yqq
  if [[ "$JAVA_VERSION" == "8" ]]; then
    JAVA_VERSION="1.8.0"
  fi
  PACKAGE="java-${JAVA_VERSION}-amazon-corretto-jdk"
  if ! dpkg -s "$PACKAGE" >/dev/null 2>&1; then
    wget -O- https://apt.corretto.aws/corretto.key | sudo apt-key add -
    sudo add-apt-repository 'deb https://apt.corretto.aws stable main'
    sudo apt-get update -yqq
    sudo apt-get -yqq --no-install-suggests --no-install-recommends install "$PACKAGE" || true
    travis_cmd "export JAVA_HOME=/usr/lib/jvm/java-${JAVA_VERSION}-amazon-corretto" --echo
    travis_cmd 'export PATH="$JAVA_HOME/bin:$PATH"' --echo
    sudo update-java-alternatives -s "$PACKAGE"*
  fi
}
