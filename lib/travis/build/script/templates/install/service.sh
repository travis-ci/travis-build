sudo su -c "cat > <%= Addons::BIN_PATH %>/travis-<%= File.basename(filename, '.sh') %>" << "sh"
#!/bin/bash -e

name=$1
cmd=$2
known=" <%= Services::KNOWN_SERVICES.join(' ') %> "

if [[ ! "$known" =~ " $name " ]]; then
  echo -e "\n\033[31;1mFailed to start unknown service: $name."
  exit 1
fi

if [[ ! "start stop" =~ "$cmd" ]]; then
  echo -e "\n\033[31;1m Failed to run `service $name $cmd`. Allowed commands are: start, stop."
  exit 1
fi

echo -e "\033[33;1m$( echo $cmd | sed 's/^\(.\)/\u\1/')ing service $name\033[0m"
service $name start
sh

