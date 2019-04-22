travis_getaddrinfo() {
  local nodename="${1}"

  if [[ ! "${nodename}" ]]; then
    return
  fi

  ruby -rsocket <<EORUBY
puts Addrinfo.getaddrinfo(
  '${nodename}', nil, nil, :STREAM
).select(&:ipv4?).map(&:ip_address).sort.join("\\n")
EORUBY
}
