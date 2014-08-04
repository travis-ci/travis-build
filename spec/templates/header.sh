<%= ERB.new(File.read('lib/travis/build/script/templates/header.sh')).result(binding) %>

export HOME="<%= Travis::Build::HOME_DIR %>"

shopt -s extdebug

function generate_stub() {
  echo "function $1() {"
  echo "  $(command -v $1) \"\$@\""
  echo "}"
}

# Generate stubs for env and cat so they still work after we blank out PATH
eval "$(generate_stub env)"
eval "$(generate_stub cat)"

# Remove everything from PATH to help enforce that no external commands should
# be run in the test script.
export PATH=""

# Let's just assume that everything always works
export TRAVIS_TEST_RESULT=0

# This trap prints out the command and allows the command to be run if it
# matches the regexp at the end.
trap 'printf '"'"'%s\0'"'"' "$BASH_COMMAND"; [[ "$BASH_COMMAND" =~ ^(env|export|\[\[) ]]' DEBUG
