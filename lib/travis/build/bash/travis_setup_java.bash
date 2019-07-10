travis_setup_java() {
  local jdkpath jdk vendor version
  jdk="$1"
  vendor="$2"
  version="$3"
  jdkpath="$(travis_find_jdk_path "$jdk" "$vendor" "$version")"
  if [[ -z "$jdkpath" ]]; then
    if [[ "$TRAVIS_OS_NAME" == osx ]]; then
      java -version 2>&1 | awk -v vendor="$vendor" -v version="$version" -F'"' '
        BEGIN {
          v = "openjdk"
          if(version<9) { version = "1\\."version }
          version = "^"version"\\."
        }
        /HotSpot/ { v = "oracle" }
        /version/ { if ($2 !~ version) e++ }
        END {
          if (vendor !=v ) e++
          exit e
        }
      ' &&
        return
    fi
    travis_install_jdk "$jdk" "$vendor" "$version"
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
      sed -i "/export JAVA_HOME=/s,=.\\+,=\"$JAVA_HOME\"," ~/.bash_profile.d/travis_jdk.bash
    fi
  fi
}
