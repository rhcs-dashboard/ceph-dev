#!/usr/bin/env bash

set -eo pipefail

[[ -z "$CEPH_VERSION" ]] && export CEPH_VERSION=$("$CEPH_BIN"/ceph -v | awk '{ print substr($3,1,2) }')
[[ "$CEPH_VERSION" == 'De' ]] && export CEPH_VERSION=1000000
[[ -z "$CEPH_PATCH_VERSION" ]] && export CEPH_PATCH_VERSION=$("$CEPH_BIN"/ceph -v | sed -r 's/.*\.([0-9]*)\-.*/\1/')
[[ $(rpm -qi ceph-mgr-dashboard | grep 'Red Hat' | wc -l) > 0 ]] && export IS_UPSTREAM=0 || export IS_UPSTREAM=1
