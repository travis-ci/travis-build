travis_internal_ruby() {
  if ! type rvm &>/dev/null; then
    # shellcheck source=/dev/null
    source "${TRAVIS_HOME}/.rvm/scripts/rvm" &>/dev/null
  fi
  local i selected_ruby rubies_array_sorted rubies_array_len
  local rubies_array=()
  while IFS=$'\n' read -r line; do
    rubies_array+=("${line}")
  done < <(
    rvm list strings |
      while read -r v; do
        if [[ ! "${v}" =~ ${TRAVIS_INTERNAL_RUBY_REGEX} ]]; then
          continue
        fi
        v="${v//ruby-/}"
        v="${v%%-*}"
        echo "$(travis_vers2int "${v}")_${v}"
      done
  )
  travis_bash_qsort_numeric "${rubies_array[@]}"
  rubies_array_sorted=("${travis_bash_qsort_numeric_ret[@]}")
  rubies_array_len="${#rubies_array_sorted[@]}"
  if ((rubies_array_len <= 0)); then
    echo 'default'
  else
    i=$((rubies_array_len - 1))
    selected_ruby="${rubies_array_sorted[${i}]}"
    selected_ruby="${selected_ruby##*_}"
    echo "${selected_ruby:-default}"
  fi
}
