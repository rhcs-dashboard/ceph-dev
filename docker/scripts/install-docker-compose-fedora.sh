#!/bin/bash

set -e

# Check user privileges:
if [ "$(whoami)" != 'root' ]; then
    echo "Super-user privileges are required. Please execute it with 'sudo'."
    exit 1
fi

dnf remove -y "docker*" || true

dnf install -y dnf-plugins-core
dnf-3 config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo

dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

groupadd docker || true
usermod -aG docker "$(logname)"

systemctl enable --now firewalld

# Run SELinux in permissive mode.
setenforce 0
sed -i -E 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

systemctl enable docker
systemctl restart docker

echo "Docker successfully installed!!!"
