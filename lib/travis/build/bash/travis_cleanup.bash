travis_cleanup() {
  if [[ -n $SSH_AGENT_PID ]]; then
    kill "$SSH_AGENT_PID" &>/dev/null
  fi
}
