travis_install_jdk() {
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
