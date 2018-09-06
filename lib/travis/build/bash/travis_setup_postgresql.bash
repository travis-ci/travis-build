travis_setup_postgresql() {
  local port start_cmd stop_cmd
  local version="${1}"

  if [[ -z "${version}" ]]; then
    case "${TRAVIS_DIST}" in
    precise)
      version='9.1'
      ;;
    trusty)
      version='9.2'
      ;;
    xenial)
      version='9.6'
      ;;
    *)
      echo -e "${ANSI_RED}Unrecognized operating system.${ANSI_CLEAR}"
      ;;
    esac
  fi

  echo -e "${ANSI_YELLOW}Starting PostgreSQL v${version}${ANSI_CLEAR}"
  export PATH="/usr/lib/postgresql/${version}/bin:$PATH"

  if [[ "${TRAVIS_INIT}" == upstart ]]; then
    start_cmd="sudo service postgresql start ${version}"
    stop_cmd="sudo service postgresql stop"
  elif [[ "${TRAVIS_INIT}" == systemd ]]; then
    start_cmd="sudo systemctl start postgresql@${version}-main"
    stop_cmd="sudo systemctl stop postgresql"
  fi

  ${stop_cmd}

  sudo bash -c "
	if [[ -d /var/ramfs && ! -d \"/var/ramfs/postgresql/${version}\" ]]; then
    mkdir -p /var/ramfs/postgresql
	  cp -rp \"/var/lib/postgresql/${version}\" \"/var/ramfs/postgresql/${version}\"
	fi
  " &>/dev/null

  ${start_cmd}
  echo "${start_cmd}"

  pushd / &>/dev/null || true
  for port in 5432 5433; do
    sudo -u postgres createuser -s -p "${port}" travis
    sudo -u postgres createdb -O travis -p "${port}" travis
  done &>/dev/null
  popd &>/dev/null || true
}
