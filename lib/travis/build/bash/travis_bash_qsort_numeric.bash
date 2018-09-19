travis_bash_qsort_numeric() {
  local pivot i smaller=() larger=()
  travis_bash_qsort_numeric_ret=()
  (($# == 0)) && return 0
  pivot="${1}"
  shift
  for i; do
    if [[ "${i%%_*}" -lt "${pivot%%_*}" ]]; then
      smaller+=("${i}")
    else
      larger+=("${i}")
    fi
  done
  travis_bash_qsort_numeric "${smaller[@]}"
  smaller=("${travis_bash_qsort_numeric_ret[@]}")
  travis_bash_qsort_numeric "${larger[@]}"
  larger=("${travis_bash_qsort_numeric_ret[@]}")
  travis_bash_qsort_numeric_ret=("${smaller[@]}" "${pivot}" "${larger[@]}")
}
