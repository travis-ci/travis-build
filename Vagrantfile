# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "ubuntu/precise64"
  config.vm.box_url = "http://files.vagrantup.com/precise64.box"

  config.vm.provision "shell", privileged: true, inline: "aptitude update"
  config.vm.provision "shell", privileged: true, inline: "aptitude install -y make libyaml-dev"

  config.vm.provision "shell", privileged: true, inline: <<-EOF
    set -e
    if ! [[ -f /usr/local/share/chruby/chruby.sh ]]; then
      mkdir /tmp/chruby
      cd /tmp/chruby
      wget -qO chruby-0.3.8.tar.gz https://github.com/postmodern/chruby/archive/v0.3.8.tar.gz
      tar -xzvf chruby-0.3.8.tar.gz
      cd chruby-0.3.8/
      make install
    fi

    apt-get install -y git libssl-dev
  EOF

  config.vm.provision "shell", privileged: false, inline: <<-EOF
    set -e
    if ! [[ -d ~/.rubies/ruby-2.1.2 ]]; then
      echo "Installing Ruby 2.1.2 (this might take a while depending on your network connection)"
      mkdir ~/.rubies
      wget -qO- http://rubies.travis-ci.org/ubuntu/12.04/x86_64/ruby-2.1.2.tar.bz2 | tar -jx -C ~/.rubies
      RUBIES=(~/.rubies/*)
    fi

    echo 'source /usr/local/share/chruby/chruby.sh' >> ~/.bashrc
    echo 'chruby ruby-2.1.2' >> ~/.bashrc

    source /usr/local/share/chruby/chruby.sh
    chruby ruby-2.1.2

    gem install bundler
    bundle install --gemfile=/vagrant/Gemfile
  EOF
end
