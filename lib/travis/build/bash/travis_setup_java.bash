travis_setup_java() {
  local jdkpath jdk vendor version
  jdk="$1"
  vendor="$2"
  version="$3"
  jdkpath="$(travis_find_jdk_path "$jdk" "$vendor" "$version")"
  if [[ -z "$jdkpath" ]]; then
    if [[ "$TRAVIS_OS_NAME" == osx ]]; then
      # No action is necessary under special conditions
      if [[ "$vendor" == oracle ]]; then
        [[ "$version" == 8 ]] &&
          java -version 2>&1 | grep -qE "^java version \"1\.8\." &&
          return
        [[ "$version" == 10 ]] &&
          java -version 2>&1 | grep -qE "^java version \"10\." &&
          return
      fi
    fi
    travis_install_jdk "$vendor" "$version"
  elif compgen -G "${jdkpath%/*}/$(travis_jinfo_file "$vendor" "$version")" &>/dev/null &&
    declare -f jdk_switcher &>/dev/null; then
    travis_cmd "jdk_switcher use \"$jdk\"" --echo --assert
    if [[ -f ~/.bash_profile.d/travis_jdk.bash ]]; then
      sed -i '/export \(PATH\|JAVA_HOME\)=/d' ~/.bash_profile.d/travis_jdk.bash
    fi
  else
    export JAVA_HOME="$jdkpath"
    export PATH="$JAVA_HOME/bin:$PATH"
    if [[ -f ~/.bash_profile.d/travis_jdk.bash ]]; then
      sed -i ",export JAVA_HOME=,s,=.\\+,=\"$JAVA_HOME\"," ~/.bash_profile.d/travis_jdk.bash
    fi
  fi
}
