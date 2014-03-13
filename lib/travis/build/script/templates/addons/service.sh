sudo su -c "cat > <%= Addons::BIN_PATH %>/travis-addon-<%= File.basename(filename, '.sh') %>" << "sh"
#!/bin/bash -e

name=$1
known=" <%= Services::KNOWN_SERVICES.join(' ') %> "

if [[ ! "$known" =~ " $name " ]]; then
  echo -e "\n\033[31;1mFailed to start unknown service: $name."
  exit 1
fi

echo -e "\033[33;1mStarting service $name\033[0m"
service $name start
sh

