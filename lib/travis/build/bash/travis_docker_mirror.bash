travis_docker_mirror() {
  [[ "$TRAVIS_OS_NAME" != linux ]] && return
  [[ -f /.dockerenv ]] && return
  sudo bash -c '[[ -f /etc/docker/daemon.json ]]' && return
  sudo bash <<-'EOPIPE'
		echo '{
		  "registry-mirrors": ["https://mirror.gcr.io"]
		}' >/etc/docker/daemon.json
	EOPIPE
  case "$TRAVIS_INIT" in
    upstart)
      sudo service docker restart &>/dev/null
      ;;
    systemd)
      sudo systemctl restart docker &>/dev/null
      ;;
    *)
      echo 'Unknown init system'>/dev/stderr
      ;;
  esac
}
