travis_remove_from_path() {
  target="$1"
  export PATH="$(
    echo $PATH: \
      | tr : '\n' \
      | grep -v \"^$p$\" \
      | tr '\n' : \
      | sed 's/:$//'
    )"
}

travis_find_jdk_path() {
  local jdkpath result
  shopt -s nullglob
  for jdkpath in <%= jdk_glob %>; do
    [[ ! -d "$jdkpath" ]] && continue
    result="$jdkpath"
    break
  done
  shopt -u nullglob
  echo "$result"
}

travis_install_jdk() {
  local jdk url
  jdk="$1"
  echo -e "${ANSI_YELLOW}Acquiring install-jdk.sh${ANSI_RESET}"
  travis_cmd 'export JAVA_HOME=~/jdk' --echo
  travis_cmd 'export PATH="$JAVA_HOME/bin:$PATH"' --echo
  mkdir -p ~/bin
  url="https://<%= app_host %>/files/install-jdk.sh"
  travis_cmd curl\ -sLf\ $url\ \>\~/bin/install-jdk.sh --echo
  if [[ $? != 0 ]]; then
    url="https://raw.githubusercontent.com/sormuras/bach/master/install-jdk.sh"
    travis_cmd curl\ -sLf\ $url\ \>\~/bin/install-jdk.sh --echo --assert
  fi
  chmod +x ~/bin/install-jdk.sh
  travis_cmd "~/bin/install-jdk.sh --target \"$JAVA_HOME\" --workspace \"<%= cache_dir %>\" <%= args %>" --echo --assert
}

travis_setup_java() {
  local jdkpath
  jdkpath="$(travis_find_jdk_path)"
  if [[ -z "$jdkpath" ]]; then
    travis_install_jdk <%= jdk %>
  elif [[ -e "$jdkpath/.jinfo" ]] && declare -f jdk_switcher; then
    travis_cmd 'jdk_switcher use <%= jdk %>' --echo --assert
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

travis_setup_java

unset -f travis_remove_from_path \
  travis_set_java \
  travis_install_jdk
