if which npm >/dev/null; then
  echo -e "\033[33;1mApplying fix for NPM certificates\033[0m"
  npm config set ca ""
fi
