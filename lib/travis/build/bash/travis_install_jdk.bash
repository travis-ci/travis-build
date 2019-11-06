travis_install_jdk() {
  local url vendor version license jdk certlink
  jdk="$1"
  vendor="$2"
  version="$3"
  case "${TRAVIS_CPU_ARCH}" in
  "arm64"|"s390x"|"ppc64le")
    travis_install_jdk_compiled $version
  ;;
  *)
    travis_install_jdk_ext_provider "$jdk" "$vendor" "$version"
  ;;
  esac
}

travis_install_jdk_ext_provider(){
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
    url="https://raw.githubusercontent.com/sormuras/bach/master/install-jdk.sh"
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


travis_install_jdk_compiled(){
  local JAVA_URL
  local JAVA_VERSION
  local UNAME_ARCH
  UNAME_ARCH=$(uname -m)
  JAVA_VERSION="$1"
  JAVA_URL="https://travis-java-archives.s3.amazonaws.com/binaries/$(source /usr/lib/os-release;echo $ID)/$(source /usr/lib/os-release;echo $VERSION_ID)/${UNAME_ARCH}/linux-openjdk${JAVA_VERSION}.tar.bz2"

  travis_cmd "sudo mkdir -p /usr/local/lib/openjdk${JAVA_VERSION}"

  sudo curl -s ${JAVA_URL} | sudo tar xjf - -C /usr/local/lib/openjdk${JAVA_VERSION} --strip-components 1
  if [ $? -ne 0 ];then
    echo "${ANSI_RED}Could not download java ${JAVA_VERSION} for arch ${UNAME_ARCH} ${ANSI_RESET}"
    travis_terminate 2
  fi

  echo "if [[ -d /usr/local/lib/openjdk${JAVA_VERSION} ]]; then
  export JAVA_HOME=/usr/local/lib/openjdk${JAVA_VERSION}
  export PATH="\$JAVA_HOME/bin:\$PATH"
fi
" > /home/travis/.bash_profile.d/travis-java.bash
  sudo chmod 644 /home/travis/.bash_profile.d/travis-java.bash
  sudo chown travis:travis /home/travis/.bash_profile.d/travis-java.bash
  export JAVA_HOME="/usr/local/lib/openjdk${JAVA_VERSION}"
  export PATH="${JAVA_HOME}/bin:${PATH}"
}


