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
    travis_install_jdk_package_adoptium "$version" "$vm"
  elif [[ "$vendor" == "semeru" ]]; then
    travis_install_jdk_package_semeru "$version"
  else
    case "${TRAVIS_CPU_ARCH}" in
    "s390x" | "ppc64le")
      travis_install_jdk_package_adoptium "$version" "$vm"
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

# Provider only for s390x and ppc64le
travis_install_jdk_package_adoptium() {
  local JAVA_VERSION
  JAVA_VERSION="$1"
  sudo apt-get update -yqq
  PACKAGE="temurin-${JAVA_VERSION}-jdk"
  if ! dpkg -s "$PACKAGE" >/dev/null 2>&1; then
    if [[ "${TRAVIS_CPU_ARCH}" == "ppc64le" ]]; then
      wget -O - https://adoptium.jfrog.io/artifactory/api/security/keypair/default-gpg-key/public | sudo apt-key add -
      sudo add-apt-repository --yes https://packages.adoptium.net/artifactory/deb
      sudo apt-get update -yqq
      sudo apt-get -yqq --no-install-suggests --no-install-recommends install "$PACKAGE" || true
      travis_cmd "export JAVA_HOME=/usr/lib/jvm/$PACKAGE-ppc64el" --echo
      travis_cmd "export PATH=$JAVA_HOME/bin:$PATH" --echo
      sudo update-java-alternatives -s "$PACKAGE"-ppc64el
    else
      wget -O - https://adoptium.jfrog.io/artifactory/api/security/keypair/default-gpg-key/public | sudo apt-key add -
      sudo add-apt-repository --yes https://packages.adoptium.net/artifactory/deb
      sudo apt-get update -yqq
      sudo apt-get -yqq --no-install-suggests --no-install-recommends install "$PACKAGE" || true
      travis_cmd "export JAVA_HOME=/usr/lib/jvm/$PACKAGE-s390x" --echo
      travis_cmd "export PATH=$JAVA_HOME/bin:$PATH" --echo
      sudo update-java-alternatives -s "$PACKAGE"-s390x
    fi
  fi
  # `realpath` is preinstalled in Ubuntu Xenial+ and OSX 10.11+ Homebrew
  # shellcheck disable=SC2016
  travis_cmd 'export JAVA_HOME="$(realpath -Pm "$(which javac)/../../")"' --echo
  # no need to alter PATH because `adoptopenjdk` installs executables with `update-alternatives`
}

# Provider only for amd and arm64
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
      sudo add-apt-repository --yes "deb [arch=$TRAVIS_CPU_ARCH] https://apt.bell-sw.com/ stable main"
      sudo apt-get update -yqq
      sudo apt-get -yqq --no-install-suggests --no-install-recommends install "$PACKAGE" || true
      travis_cmd "export JAVA_HOME=/usr/lib/jvm/bellsoft-java${JAVA_VERSION}-aarch64" --echo
      travis_cmd "export PATH=$JAVA_HOME/bin:$PATH" --echo
      sudo update-java-alternatives -s "$PACKAGE"*
    else
      wget -qO - https://download.bell-sw.com/pki/GPG-KEY-bellsoft | sudo apt-key add -
      sudo add-apt-repository --yes "deb [arch=$TRAVIS_CPU_ARCH] https://apt.bell-sw.com/ stable main"
      sudo apt-get update -yqq
      sudo apt-get -yqq --no-install-suggests --no-install-recommends install "$PACKAGE" || true
      travis_cmd "export JAVA_HOME=/usr/lib/jvm/bellsoft-java${JAVA_VERSION}-${TRAVIS_CPU_ARCH}" --echo
      travis_cmd "export PATH=$JAVA_HOME/bin:$PATH" --echo
      sudo update-java-alternatives -s "$PACKAGE"*
    fi
  fi
}

# Provider for SEMERU vendor
travis_install_jdk_package_semeru() {
  local JAVA_VERSION
  JAVA_VERSION="$1"

  if [[ "${TRAVIS_CPU_ARCH}" == "arm64" ]]; then
    TRAVIS_CPU_ARCH="aarch64"
  elif [[ "${TRAVIS_CPU_ARCH}" == "amd64" ]]; then
    TRAVIS_CPU_ARCH="x64"
  fi

  case "${JAVA_VERSION}" in
  8) JDK_URL="https://github.com/ibmruntimes/semeru8-binaries/releases/download/jdk8u412-b08_openj9-0.44.0/ibm-semeru-open-jdk_${TRAVIS_CPU_ARCH}_linux_8u412b08_openj9-0.44.0.tar.gz" ;;
  11) JDK_URL="https://github.com/ibmruntimes/semeru11-binaries/releases/download/jdk-11.0.23%2B9_openj9-0.44.0/ibm-semeru-open-jdk_${TRAVIS_CPU_ARCH}_linux_11.0.23_9_openj9-0.44.0.tar.gz" ;;
  16) JDK_URL="https://github.com/ibmruntimes/semeru16-binaries/releases/download/jdk-16.0.2%2B7_openj9-0.27.0/ibm-semeru-open-jdk_${TRAVIS_CPU_ARCH}_linux_16.0.2_7_openj9-0.27.0.tar.gz" ;;
  17) JDK_URL="https://github.com/ibmruntimes/semeru17-binaries/releases/download/jdk-17.0.11%2B9_openj9-0.44.0/ibm-semeru-open-jdk_${TRAVIS_CPU_ARCH}_linux_17.0.11_9_openj9-0.44.0.tar.gz" ;;
  18) JDK_URL="https://github.com/ibmruntimes/semeru18-binaries/releases/download/jdk-18.0.2%2B9_openj9-0.33.1/ibm-semeru-open-jdk_${TRAVIS_CPU_ARCH}_linux_18.0.2_9_openj9-0.33.1.tar.gz" ;;
  19) JDK_URL="https://github.com/ibmruntimes/semeru19-binaries/releases/download/jdk-19.0.2%2B7_openj9-0.37.0/ibm-semeru-open-jdk_${TRAVIS_CPU_ARCH}_linux_19.0.2_7_openj9-0.37.0.tar.gz" ;;
  20) JDK_URL="https://github.com/ibmruntimes/semeru20-binaries/releases/download/jdk-20.0.2%2B9_openj9-0.40.0/ibm-semeru-open-jdk_${TRAVIS_CPU_ARCH}_linux_20.0.2_9_openj9-0.40.0.tar.gz" ;;
  21) JDK_URL="https://github.com/ibmruntimes/semeru21-binaries/releases/download/jdk-21.0.3%2B9_openj9-0.44.0/ibm-semeru-open-jdk_${TRAVIS_CPU_ARCH}_linux_21.0.3_9_openj9-0.44.0.tar.gz" ;;
  22) JDK_URL="https://github.com/ibmruntimes/semeru22-binaries/releases/download/jdk-22.0.1%2B8_openj9-0.45.0/ibm-semeru-open-jdk_${TRAVIS_CPU_ARCH}_linux_22.0.1_8_openj9-0.45.0.tar.gz" ;;
  *) echo "JDK ${JAVA_VERSION} missing in the Semeru repository. Please choose a different version." ;;
  esac

  # Define the installation directory
  INSTALL_DIR="/usr/lib/jvm"

  # Download the JDK tarball
  wget -q "$JDK_URL" -O jdk.tar.gz

  # Extract the tarball
  sudo mkdir $INSTALL_DIR/jdk"${JAVA_VERSION}" && sudo tar -xzf jdk.tar.gz --strip-components 1 -C "$INSTALL_DIR/jdk${JAVA_VERSION}"

  export JAVA_HOME="$INSTALL_DIR/jdk${JAVA_VERSION}"
  export PATH=$JAVA_HOME/bin:$PATH

  # shellcheck source=/dev/null
  source ~/.bashrc

  # Verify Java version
  java --version

}
