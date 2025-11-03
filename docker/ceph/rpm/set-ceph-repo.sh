#!/bin/bash

set -e

if [[ "${USE_REPO_FILES}" == 1 ]]; then
    mv /root/*.repo /etc/yum.repos.d
    exit 0
fi

echo "Setting target architecture for repo: $TARGETARCH"

if [ "$TARGETARCH" = "amd64" ]; then
    ARCH_NAME="x86_64"
    ARCH_DIR="x86_64"
else
    ARCH_NAME="arm64"
    ARCH_DIR="aarch64"
fi

if [[ -z "$REPO_URL" ]]; then
    if [[ -z "$CEPH_RELEASE" ]]; then
        CEPH_RELEASE=main
    fi

    REPO_URL=$(curl -s "https://shaman.ceph.com/api/search/?project=ceph&distros=centos/$CENTOS_VERSION/${ARCH_NAME}&flavor=default&ref=$CEPH_RELEASE&sha1=latest" | jq -r '.[0] | .url')/${ARCH_DIR}/
fi

echo "
[ceph-rpm]
name=Ceph RPM
baseurl=$REPO_URL
enabled=1
gpgcheck=0
" > /etc/yum.repos.d/ceph.repo

readonly REPO_URL_NOARCH=$(echo "$REPO_URL" | sed -e "s/${ARCH_DIR}/noarch/")
readonly REPO_URL_NOARCH_STATUS_CODE=$(curl -LIfs "$REPO_URL_NOARCH" | head -1 | awk '{print $2}')

if [[ "$REPO_URL_NOARCH_STATUS_CODE" == 200 ]]; then
    echo "
[ceph-rpm-noarch]
name=Ceph RPM noarch
baseurl=$REPO_URL_NOARCH
enabled=1
gpgcheck=0
" >> /etc/yum.repos.d/ceph.repo
fi
