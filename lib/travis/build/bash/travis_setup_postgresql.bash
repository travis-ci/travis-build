travis_setup_postgresql() {
  local port=5432 start_cmd stop_cmd
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
    bionic)
      version='10'
      ;;
    focal)
      version='13'
      ;;
    jammy)
      version='14'
      ;;
    noble)
      version='16'
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

  sudo pg_dropcluster --stop "${version}" main || true

  sudo pg_createcluster "${version}" main

  sudo sed -i "s/^port = .*/port = ${port}/" "/etc/postgresql/${version}/main/postgresql.conf"

  for existing_version in $(pg_lsclusters | grep "${port}" | awk '{print $1}'); do
    if [ "${existing_version}" != "${version}" ]; then
      sudo pg_ctlcluster "${existing_version}" main stop || true
    fi
  done

  sudo bash -c "
	if [[ -d /var/ramfs && ! -d \"/var/ramfs/postgresql/${version}\" ]]; then
    mkdir -p /var/ramfs/postgresql
	  cp -rp \"/var/lib/postgresql/${version}\" \"/var/ramfs/postgresql/${version}\"
	fi
  " &>/dev/null

  sudo sed -i "s/^local.*postgres.*peer$/local   all             postgres                                trust/" "/etc/postgresql/${version}/main/pg_hba.conf"
  sudo sed -i "s/^host.*all.*all.*127.0.0.1\\/32.*md5$/host    all             all             127.0.0.1\\/32            trust/" "/etc/postgresql/${version}/main/pg_hba.conf"

  ${start_cmd}
  echo "${start_cmd}"

  sleep 2

  pushd / &>/dev/null || true
  sudo -u postgres createuser -s -p "${port}" travis
  sudo -u postgres createdb -O travis -p "${port}" travis
  popd &>/dev/null || true
}
