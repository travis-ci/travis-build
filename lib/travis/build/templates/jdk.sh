travis_remove_from_path() {
  target="$1"
  export PATH="$(
    echo $PATH:        |
      tr : '\n'        |
      grep -v \"^$p$\" |
      tr '\n' :        |
      sed 's/:$//'
    )"
}

travis_find_jdk_path() {
  local vendor version jdkpath result jdk
  jdk="$1"
  vendor="$2"
  version="$3"
  shopt -s nullglob
  if [[ "$vendor" == "openjdk" ]]; then
    apt_glob="/usr/lib/jvm/java-1.${version}.*openjdk*"
  elif [[ "$vendor" == "oracle"]]; then
    apt_glob="/usr*/lib/jvm/java-${version}-oracle"
  fi
  for jdkpath in $apt_glob "/usr*/local/lib/jvm/${jdk}"; do
    [[ ! -d "$jdkpath" ]] && continue
    result="$jdkpath"
    break
  done
  shopt -u nullglob
  echo "$result"
}

travis_jinfo_file() {
  local vendor version
  vendor="$1"
  version="$2"
  if [[ "$vendor" == oracle ]]; then
    echo ".java-${version}-${vendor}.jinfo"
  elif [[ "$vendor" == openjdk ]]; then
    echo ".java-1.${version}.*-${vendor}-*.jinfo"
  fi
}

travis_install_jdk() {
  local jdk url vendor version license
  jdk="$1"
  vendor="$2"
  version="$3"
  if [[ "$vendor" == openjdk ]]; then
    license=GPL
  elif [[ "$vendor" == oracle ]]; then
    license=BCL
  fi
  echo -e "${ANSI_YELLOW}Acquiring install-jdk.sh${ANSI_RESET}"
  travis_cmd 'export JAVA_HOME=~/jdk' --echo
  travis_cmd 'export PATH="$JAVA_HOME/bin:$PATH"' --echo
  mkdir -p ~/bin
  url="https://$TRAVIS_APP_HOST/files/install-jdk.sh"
  travis_cmd curl\ -sLf\ $url\ \>\~/bin/install-jdk.sh --echo
  if [[ $? != 0 ]]; then
    url="https://raw.githubusercontent.com/sormuras/bach/master/install-jdk.sh"
    travis_cmd curl\ -sLf\ $url\ \>\~/bin/install-jdk.sh --echo --assert
  fi
  chmod +x ~/bin/install-jdk.sh
  travis_cmd "~/bin/install-jdk.sh --target \"$JAVA_HOME\" --workspace \"$TRAVIS_HOME/.cache/install-jdk\" --feature \"$version\" --license \"$license\"" --echo --assert
}

travis_setup_java() {
  local jdkpath jdk vendor version
  jdk="$1"
  vendor="$2"
  version="$3"
  jdkpath="$(travis_find_jdk_path \"$jdk\" \"$vendor\" \"$version\")"
  echo debug: "${jdkpath%/*}/.${jdkpath##*/}.jinfo" $([[ -f "${jdkpath%/*}/.${jdkpath##*/}.jinfo" ]] && echo exists || echo does not exist)
  if [[ -z "$jdkpath" ]]; then
    echo 'debug: empty jdkpath'
    travis_install_jdk "$jdk" "$vendor" "$version"
  elif compgen -G "${jdkpath%/*}/$(travis_jinfo_file \"$vendor\" \"$version\")" &>/dev/null \
      && declare -f jdk_switcher &>/dev/null; then
    echo 'debug: .jinfo file found'
    travis_cmd "jdk_switcher use \"$jdk\""  --echo --assert
    travis_remove_from_path "$JAVA_HOME/bin"
    unset JAVA_HOME
    if [[ -f ~/.bash_profile.d/travis_jdk.bash ]]; then
      sed -i '/export \(PATH\|JAVA_HOME\)=/d' ~/.bash_profile.d/travis_jdk.bash
    fi
  else
    export JAVA_HOME="$jdkpath"
    export PATH="$JAVA_HOME/bin:$PATH"
    if [[ -f ~/.bash_profile.d/travis_jdk.bash ]]; then
      sed -i "/export JAVA_HOME=/s/=.\+/=\"$JAVA_HOME\"/" ~/.bash_profile.d/travis_jdk.bash
    fi
  fi
}
