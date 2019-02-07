travis_script_go() {
  local gobuild_args="${1}"

  if travis_has_makefile; then
    travis_cmd make
  else
    travis_cmd "go test ${gobuild_args} ./..."
  fi
}
