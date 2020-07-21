#!/bin/bash

set -e

# Check user privileges:
if [ "$(whoami)" != 'root' ]; then
    echo "Super-user privileges are required. Please execute it with 'sudo'."
    exit 1
fi

dnf remove -y "docker*" || true

dnf install -y dnf-plugins-core grubby

dnf info moby-engine >/dev/null 2>&1
MOBY_ENGINE_EXISTS=$?
if [[ ${MOBY_ENGINE_EXISTS} == 0 ]]; then
    dnf install -y moby-engine
else
    dnf config-manager \
        --add-repo \
        https://download.docker.com/linux/fedora/docker-ce.repo

#    dnf config-manager --set-disabled docker-ce-nightly
#    dnf config-manager --set-disabled docker-ce-test

    dnf install -y docker-ce
fi

groupadd docker || true
usermod -aG docker "$(logname)"

FEDORA_VERSION=$(sed -nE 's/^VERSION_ID=(.*)$/\1/p' /etc/os-release)
if [[ "${FEDORA_VERSION}" -ge 32 ]]; then
    # Docker does not yet cooperate with the nftables backend.
    firewall-cmd --permanent --zone=trusted --add-interface=docker0 || true
    firewall-cmd --permanent --zone=trusted --add-source=172.0.0.0/8 || true
    firewall-cmd --reload
fi

# Run SELinux in permissive mode.
setenforce 0
sed -i -E 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

systemctl enable docker
systemctl restart docker

readonly dockerComposeVersion='1.21.0'

curl -Ls "https://github.com/docker/compose/releases/download/$dockerComposeVersion/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

echo "Docker successfully installed!!!"

if [[ "${FEDORA_VERSION}" -ge 31 ]]; then
    # Docker does not yet support Control Group V2.
    grubby --update-kernel=ALL --args="systemd.unified_cgroup_hierarchy=0"

    echo "Please reboot in order for Cgroups backward compatibility to take effect."
else
    echo "Please log out and log in in order to use docker without 'sudo'."
fi
