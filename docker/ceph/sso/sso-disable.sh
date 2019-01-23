#!/bin/bash

set -e

cd /ceph/build

CEPH_BIN=bin/ceph
if [[ ! -e "$CEPH_BIN" ]]; then
    CEPH_BIN=/usr/bin/ceph
fi

"$CEPH_BIN" dashboard sso disable
