travis_script_go() {
  local gobuild_args="${1}"

  if [[ -f GNUmakefile || -f makefile || -f Makefile || -f BSDmakefile ]]; then
    travis_cmd make
  else
    travis_cmd "go test ${gobuild_args} ./..."
  fi
}
