travis_start_sauce_connect() {
  if [[ ! "${SAUCE_USERNAME}" || ! "${SAUCE_ACCESS_KEY}" ]]; then
    echo "This script runs only when Sauce credentials are present"
    echo "Please set SAUCE_USERNAME and SAUCE_ACCESS_KEY env variables"
    echo "export SAUCE_USERNAME=ur-username"
    echo "export SAUCE_ACCESS_KEY=ur-access-key"
    return 0
  fi

  local sc_tmp sc_platform sc_archive sc_distro_fmt \
    sc_readyfile sc_logfile sc_tunnel_id_arg sc_bin

  sc_tmp="$(mktemp -d -t sc.XXXX)"
  echo "Using temp dir ${sc_tmp}"
  pushd "${sc_tmp}" || true

  sc_platform=$(uname | sed -e 's/Darwin/osx/' -e 's/Linux/linux/')
  case "${sc_platform}" in
  linux)
    sc_distro_fmt=tar.gz
    sc_archive=sc-linux.tar.gz
    ;;
  osx)
    sc_distro_fmt=zip
    sc_archive=sc-osx.zip
    ;;
  esac

  sc_readyfile="sauce-connect-ready-${RANDOM}"
  sc_logfile="${TRAVIS_HOME}/sauce-connect.log"
  if [ ! -z "${TRAVIS_JOB_NUMBER}" ]; then
    sc_tunnel_id_arg="-i ${TRAVIS_JOB_NUMBER}"
  fi
  echo 'Downloading Sauce Connect'
  if ! travis_download "https://${TRAVIS_SAUCE_CONNECT_APP_HOST}/files/${sc_archive}"; then
    # fall back to fetching from Sauce Labs
    case "${sc_platform}" in
    linux)
      sc_download_url="${TRAVIS_SAUCE_CONNECT_LINUX_DOWNLOAD_URL}"
      ;;
    osx)
      sc_download_url="${TRAVIS_SAUCE_CONNECT_OSX_DOWNLOAD_URL}"
      ;;
    esac

    travis_download "${sc_download_url}" "${sc_archive}"
  fi

  echo 'Extracting Sauce Connect'
  case "${sc_distro_fmt}" in
  tar.gz)
    tar zxf sc-linux.tar.gz
    ;;
  zip)
    unzip sc-osx.zip
    ;;
  esac

  sc_bin="$(find sc-* -type f -perm -0500 -name sc)"

  # shellcheck disable=SC2086
  "${sc_bin}" \
    ${sc_tunnel_id_arg} \
    -f ${sc_readyfile} \
    -l ${sc_logfile} \
    ${SAUCE_NO_SSL_BUMP_DOMAINS} \
    ${SAUCE_DIRECT_DOMAINS} \
    ${SAUCE_TUNNEL_DOMAINS} &
  TRAVIS_SAUCE_CONNECT_PID="${!}"

  echo "Waiting for Sauce Connect readyfile"
  while test ! -f "${sc_readyfile}" && ps -f "${TRAVIS_SAUCE_CONNECT_PID}" &>/dev/null; do
    sleep .5
  done

  if test ! -f "${sc_readyfile}"; then
    echo "readyfile not created"
  fi

  test -f "${sc_readyfile}"
  _result="${?}"

  popd || true

  return "${_result}"
}
