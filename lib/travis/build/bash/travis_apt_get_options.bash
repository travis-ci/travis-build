travis_apt_get_options() {
  # NOTE: set `--allow-.+` options if apt version is >= 1.2 or 2.x+
  apt-get --version | awk '
    $1 == "apt" {
      split($2, apt, ".")
      if ((apt[1]==1 && apt[2]>=2) || apt[1]>1) {
        print "--allow-downgrades --allow-remove-essential --allow-change-held-packages"
      }
      else {
        print "--force-yes"
      }
      exit
    }
  '
}
