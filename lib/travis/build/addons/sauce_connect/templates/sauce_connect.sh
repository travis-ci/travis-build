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

  local sc_tmp sc_distro_fmt \
    sc_readyfile sc_logfile sc_dir sc_tunnel_id_arg sc_actual_shasum

  sc_tmp="$(mktemp -d -t sc.XXXX)"
  echo "Using temp dir $sc_tmp"
  pushd $sc_tmp

  sc_distro_fmt=<%= archive.gsub(/sc-[^.]+\./,'') %>

  sc_readyfile=sauce-connect-ready-$RANDOM
  sc_logfile=$HOME/sauce-connect.log
  if [ ! -z "${TRAVIS_JOB_NUMBER}" ]; then
    sc_tunnel_id_arg="-i ${TRAVIS_JOB_NUMBER}"
  fi
  echo "Downloading Sauce Connect"
  curl -o <%= archive %> -sf https://<%= app_host %>/files/<%= archive %>

  case ${sc_distro_fmt} in
    tar.gz)
      sc_dir=$(tar -ztf <%= archive %> | head -n1);;
    zip)
      sc_dir=$(unzip -l <%= archive %> | sed '0,/^---/d' | sed '/^---/,$d' | head -n 1 | awk '{print $NF}' | sed 's:/$::');;
  esac

  echo "Extracting Sauce Connect"
  case "${sc_distro_fmt}" in
      tar.gz)
          tar zxf <%= archive %>;;
      zip)
          unzip <%= archive %>;;
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
  while test ! -f ${sc_readyfile} && ps -f $_SC_PID >&/dev/null; do
    sleep .5
  done

  if test ! -f ${sc_readyfile}; then
    echo "readyfile not created"
  fi

  test -f ${sc_readyfile}
  _result=$?

  popd

  return $_result
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
