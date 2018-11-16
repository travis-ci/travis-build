travis_getaddrinfo() {
  local nodename="${1}"

  if [[ ! "${nodename}" ]]; then
    return
  fi

  # shellcheck disable=SC1010
  rvm "$(travis_internal_ruby)" --fuzzy do ruby -rsocket <<EORUBY
puts Addrinfo.getaddrinfo(
  '${nodename}', nil, nil, :STREAM
).select(&:ipv4?).map(&:ip_address).sort.join("\\n")
EORUBY
}
