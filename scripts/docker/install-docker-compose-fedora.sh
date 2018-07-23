#!/bin/bash

set -e

# Check user privileges:
if [ "$(whoami)" != 'root' ]; then
    echo "Super-user privileges are required. Please execute it with 'sudo'."
    exit 1
fi

dnf remove docker* || true

dnf install -y dnf-plugins-core

dnf config-manager \
    --add-repo \
    https://download.docker.com/linux/fedora/docker-ce.repo

dnf config-manager --set-enabled docker-ce-edge
dnf config-manager --set-enabled docker-ce-test

dnf install -y docker-ce

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
