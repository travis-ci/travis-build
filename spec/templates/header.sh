<%= ERB.new(File.read('lib/travis/build/script/templates/header.sh')).result(binding) %>

export HOME="<%= Travis::Build::HOME_DIR %>"

shopt -s extdebug

function generate_stub() {
  echo "function $1() {"
  echo "  $(command -v $1) \"\$@\""
  echo "}"
}

eval "$(generate_stub env)"
eval "$(generate_stub cat)"

export PATH=""

# Let's just assume that everything always works
export TRAVIS_TEST_RESULT=0

trap 'printf '"'"'%s\0'"'"' "$BASH_COMMAND"; [[ "$BASH_COMMAND" =~ ^(env|export|\[\[) ]]' DEBUG
