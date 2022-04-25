#!/bin/bash

set -e 

# check user privileges:
if [ "$(whoami)" != 'root' ]; then
    echo "Super-user privileges are required. Please execute it with 'sudo'."
    exit 1
fi

# Install kernel extra's to enable docker aufs support
# sudo apt-get -y install linux-image-extra-$(uname -r)

# Add Docker PPA and install latest version
# sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
# sudo sh -c "echo deb https://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list"
# sudo apt-get update
# sudo apt-get install lxc-docker -y

# Alternatively you can use the official docker install script
# wget -qO- https://get.docker.com/ | sh

# Install docker from ubuntu repository 
sudo apt remove --yes docker docker-engine docker.io containerd runc || true
sudo apt-get update
sudo apt-get upgrade
sudo apt install docker.io
systemctl start docker
systemctl enable docker

# Install docker-compose
readonly dockerComposeVersion='1.21.0'

curl -Ls "https://github.com/docker/compose/releases/download/$dockerComposeVersion/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

echo "Docker successfully installed!!!!"

# Install docker-cleanup command
cd /tmp
git clone https://gist.github.com/76b450a0c986e576e98b.git
cd 76b450a0c986e576e98b
sudo mv docker-cleanup /usr/local/bin/docker-cleanup
sudo chmod +x /usr/local/bin/docker-cleanup