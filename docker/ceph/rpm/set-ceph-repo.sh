#!/bin/bash

set -e

readonly REPO_URL_NOARCH=$(echo "$REPO_URL" | sed -e 's/x86_64/noarch/')

echo "
[ceph-rpm]
name=Ceph RPM
baseurl=$REPO_URL
enabled=1
gpgcheck=0

[ceph-rpm-noarch]
name=Ceph RPM noarch
baseurl=$REPO_URL_NOARCH
enabled=1
gpgcheck=0
" > /etc/yum.repos.d/ceph.repo
