#!/bin/bash

export _SC_PID=unset

function travis_start_sauce_connect() {
  if [ -z "${SAUCE_USERNAME}" ] || [ -z "${SAUCE_ACCESS_KEY}" ]; then
      echo "This script can't run without your Sauce credentials"
      echo "Please set SAUCE_USERNAME and SAUCE_ACCESS_KEY env variables"
      echo "export SAUCE_USERNAME=ur-username"
      echo "export SAUCE_ACCESS_KEY=ur-access-key"
      return 1
  fi

  local sc_tmp sc_platform sc_distro sc_distro_fmt sc_distro_shasum \
    sc_readyfile sc_logfile sc_dir sc_tunnel_id_arg sc_actual_shasum

  sc_tmp="$(mktemp -d -t sc.XXXX)"
  echo "Using temp dir $sc_tmp"
  pushd $sc_tmp

  sc_platform=$(uname | sed -e 's/Darwin/osx/' -e 's/Linux/linux/')
  case "${sc_platform}" in
      linux)
          sc_distro_fmt=tar.gz
          sc_distro_shasum=8c24f989091e869d9a0cc387c3197590a1f20521;;
      osx)
          sc_distro_fmt=zip
          sc_distro_shasum=99c2577373d31061af4c6c24c53f65fdbd7f17c0;;
  esac
  sc_distro=sc-4.3.12-${sc_platform}.${sc_distro_fmt}
  sc_readyfile=sauce-connect-ready-$RANDOM
  sc_logfile=$HOME/sauce-connect.log
  if [ ! -z "${TRAVIS_JOB_NUMBER}" ]; then
    sc_tunnel_id_arg="-i ${TRAVIS_JOB_NUMBER}"
  fi
  echo "Downloading Sauce Connect"
  wget http://saucelabs.com/downloads/${sc_distro}
  sc_actual_shasum="$(openssl sha1 ${sc_distro} | cut -d' ' -f2)"
  if [[ "$sc_actual_shasum" != "$sc_distro_shasum" ]]; then
      echo "SHA1 sum of Sauce Connect file didn't match!"
      return 1
  fi
  sc_dir=$(tar -ztf ${sc_distro} | head -n1)

  echo "Extracting Sauce Connect"
  case "${sc_distro_fmt}" in
      tar.gz)
          tar zxf $sc_distro;;
      zip)
          unzip $sc_distro;;
  esac

  ${sc_dir}/bin/sc \
    ${sc_tunnel_id_arg} \
    -f ${sc_readyfile} \
    -l ${sc_logfile} \
    ${SAUCE_NO_SSL_BUMP_DOMAINS} \
    ${SAUCE_DIRECT_DOMAINS} \
    ${SAUCE_TUNNEL_DOMAINS} &
  _SC_PID="$!"

  echo "Waiting for Sauce Connect readyfile"
  while [ ! -f ${sc_readyfile} ]; do
    sleep .5
  done

  popd
}

function travis_stop_sauce_connect() {
  if [[ ${_SC_PID} = unset ]] ; then
    echo "No running Sauce Connect tunnel found"
    return 1
  fi

  kill ${_SC_PID}

  for i in 0 1 2 3 4 5 6 7 8 9 ; do
    if kill -0 ${_SC_PID} &>/dev/null ; then
      echo "Waiting for graceful Sauce Connect shutdown"
      sleep 1
    else
      echo "Sauce Connect shutdown complete"
      return 0
    fi
  done

  if kill -0 ${_SC_PID} &>/dev/null ; then
    echo "Forcefully terminating Sauce Connect"
    kill -9 ${_SC_PID} &>/dev/null || true
  fi
}
