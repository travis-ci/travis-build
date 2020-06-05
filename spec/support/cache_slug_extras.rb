# concatenation of:
#   1. config[:os]
#   2. config[:dist], (nil for specs)
#   3. SHA256 digest of env var array ["FOO=foo"], joined with '='
#      i.e., OpenSSL::Digest::SHA256.hexdigest(Array(["FOO=foo"]).sort.join('='))
# with '-'
CACHE_SLUG_EXTRAS='linux-d5b6dcf6629e552946e7baf3fc0aca4de552e1cd76b596a2800194fe085a53f7'
CACHE_SLUG_EXTRAS_FREEBSD='freebsd-d5b6dcf6629e552946e7baf3fc0aca4de552e1cd76b596a2800194fe085a53f7'
