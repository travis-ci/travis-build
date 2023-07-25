travis_install_jdk() {
  # shellcheck disable=SC2034
  local url vendor version license jdk certlink vm
  # shellcheck disable=SC2034
  jdk="$1"
  # shellcheck disable=SC2034
  vendor="$2"
  # shellcheck disable=SC2034
  version="$3"
  vm="hotspot"

  if [[ "$vendor" == "eclipse" ]]; then
    vm="openj9"
    travis_install_jdk_package_adoptopenjdk "$version" "$vm"
  else
    case "${TRAVIS_CPU_ARCH}" in
    "s390x" | "ppc64le")
      travis_install_jdk_package_adoptopenjdk "$version" "$vm"
      ;;
    "amd64")
      case "${TRAVIS_DIST}" in
      "trusty")
        travis_jdk_trusty "$version"
        ;;
      *)
        travis_install_jdk_package_bellsoft "$version"
        ;;
      esac
      ;;
    "arm64")
      travis_install_jdk_package_bellsoft "$version"
      ;;
    esac
  fi

}

# Trusty image issues with new jdk provider
travis_jdk_trusty() {
  local JAVA_VERSION
  JAVA_VERSION="$1"
  sudo apt-get update -yqq
  PACKAGE="java-${JAVA_VERSION}-openjdk-amd64"
  sudo apt install openjdk-"$JAVA_VERSION"-jdk
  travis_cmd "export JAVA_HOME=/usr/lib/jvm/$PACKAGE" --echo
  travis_cmd "export PATH=$JAVA_HOME/bin:$PATH" --echo
}

travis_install_jdk_package_adoptopenjdk() {
  local JAVA_VERSION
  JAVA_VERSION="$1"
  sudo apt-get update -yqq
  PACKAGE="adoptopenjdk-${JAVA_VERSION}-${vm}"
  if ! dpkg -s "$PACKAGE" >/dev/null 2>&1; then
    if dpkg-query -l adoptopenjdk* >/dev/null 2>&1; then
      dpkg-query -l adoptopenjdk* | grep adoptopenjdk | awk '{print $2}' | xargs sudo dpkg -P
    fi
    if [[ "${TRAVIS_CPU_ARCH}" == "ppc64le" ]]; then
      wget -qO - https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public | sudo apt-key add -
      sudo add-apt-repository --yes https://adoptopenjdk.jfrog.io/adoptopenjdk/deb/
      sudo apt-get update -yqq
      sudo apt-get -yqq --no-install-suggests --no-install-recommends install "$PACKAGE" || true
      travis_cmd "export JAVA_HOME=/usr/lib/jvm/adoptopenjdk-${JAVA_VERSION}-hotspot-ppc64el" --echo
      travis_cmd "export PATH=$JAVA_HOME/bin:$PATH" --echo
      sudo update-java-alternatives -s "$PACKAGE"*
    else
      wget -qO - https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public | sudo apt-key add -
      sudo add-apt-repository --yes https://adoptopenjdk.jfrog.io/adoptopenjdk/deb/
      sudo apt-get update -yqq
      sudo apt-get -yqq --no-install-suggests --no-install-recommends install "$PACKAGE" || true
      travis_cmd "export JAVA_HOME=/usr/lib/jvm/adoptopenjdk-${JAVA_VERSION}-hotspot-${TRAVIS_CPU_ARCH}" --echo
      travis_cmd "export PATH=$JAVA_HOME/bin:$PATH" --echo
      sudo update-java-alternatives -s "$PACKAGE"*
    fi
  fi
}

travis_install_jdk_package_bellsoft() {
  local JAVA_VERSION
  JAVA_VERSION="$1"
  sudo apt-get update -yqq
  if [[ "$JAVA_VERSION" == "8" ]]; then
    JAVA_VERSION="1.8.0"
  fi
  PACKAGE="bellsoft-java${JAVA_VERSION}"
  if ! dpkg -s "$PACKAGE" >/dev/null 2>&1; then
    if [[ "${TRAVIS_CPU_ARCH}" == "arm64" ]]; then
      wget -qO - https://download.bell-sw.com/pki/GPG-KEY-bellsoft | sudo apt-key add -
      sudo add-apt-repository "deb [arch=$TRAVIS_CPU_ARCH] https://apt.bell-sw.com/ stable main"
      sudo apt-get update -yqq
      sudo apt-get -yqq --no-install-suggests --no-install-recommends install "$PACKAGE" || true
      travis_cmd "export JAVA_HOME=/usr/lib/jvm/bellsoft-java${JAVA_VERSION}-aarch64" --echo
      travis_cmd "export PATH=$JAVA_HOME/bin:$PATH" --echo
      sudo update-java-alternatives -s "$PACKAGE"*
    else
      wget -qO - https://download.bell-sw.com/pki/GPG-KEY-bellsoft | sudo apt-key add -
      sudo add-apt-repository "deb [arch=$TRAVIS_CPU_ARCH] https://apt.bell-sw.com/ stable main"
      sudo apt-get update -yqq
      sudo apt-get -yqq --no-install-suggests --no-install-recommends install "$PACKAGE" || true
      travis_cmd "export JAVA_HOME=/usr/lib/jvm/bellsoft-java${JAVA_VERSION}-${TRAVIS_CPU_ARCH}" --echo
      travis_cmd "export PATH=$JAVA_HOME/bin:$PATH" --echo
      sudo update-java-alternatives -s "$PACKAGE"*
    fi
  fi
}
