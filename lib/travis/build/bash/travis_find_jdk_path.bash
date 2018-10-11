travis_find_jdk_path() {
  local vendor version jdkpath result jdk
  jdk="$1"
  vendor="$2"
  version="$3"
  if [[ "$vendor" == "openjdk" ]]; then
    apt_glob="/usr/lib/jvm/java-1.${version}.*openjdk*"
  elif [[ "$vendor" == "oracle" ]]; then
    apt_glob="/usr*/lib/jvm/java-${version}-oracle"
  fi
  shopt -s nullglob
  for jdkpath in /usr*/local/lib/jvm/"$jdk" $apt_glob; do
    [[ ! -d "$jdkpath" ]] && continue
    result="$jdkpath"
    break
  done
  shopt -u nullglob
  echo "$result"
}
