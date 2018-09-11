travis_disable_sudo() {
  local fake_sudo_dest="${TRAVIS_TMPDIR}/fake-sudo"
  local real_sudo
  real_sudo="$(command -v sudo)"

  sudo -n sh -c "
    chmod 4755 ${fake_sudo_dest}
    chown root:root ${fake_sudo_dest}
    mv ${fake_sudo_dest} ${real_sudo}
    find ${TRAVIS_ROOT} \\( -perm -4000 -o -perm -2000 \\) \\
      -a ! -name sudo \\
      -exec chmod a-s {} \\; 2>/dev/null &&
      sed -e 's/^%.*//' -i.bak ${TRAVIS_ROOT}/etc/sudoers &&
      rm -f ${TRAVIS_ROOT}/etc/sudoers.d/travis
  "
}
