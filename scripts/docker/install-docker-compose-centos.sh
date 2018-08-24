#!/bin/bash
set -e

# Check user privileges:
if [ "$(whoami)" != 'root' ]; then
    echo "Super-user privileges are required. Please execute it with 'sudo'."
    exit 1
fi

yum remove docker* || true

# Taken from https://www.vultr.com/docs/installing-docker-ce-on-centos-7

# Install the Docker CE dependencies.
yum install -y yum-utils device-mapper-persistent-data lvm2

# Docker provides a repository where you can fetch the stable Docker CE version. Install it with this command:
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Optional: In case you want to use the latest version of Docker CE,
# you have to enable those repositories which are disabled by default:
yum-config-manager --enable docker-ce-edge
yum-config-manager --enable docker-ce-test

# To install Docker, simply run:
yum install -y docker-ce

groupadd docker || true
usermod -aG docker "$(logname)"

systemctl enable docker
systemctl restart docker

readonly dockerComposeVersion='1.21.0'

curl -Ls "https://github.com/docker/compose/releases/download/$dockerComposeVersion/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

echo "Docker successfully installed!!!
Please log out and log in in order to use docker without 'sudo'."
