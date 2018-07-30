#!/bin/bash

set -e

mkdir -p /ceph/build

cd /ceph/build

rm -rf out dev

export CEPH_BIN=/usr/bin
export CEPH_LIB=/usr/lib
export EC_PATH=/usr/lib64/ceph/erasure-code
export MGR_PYTHON_PATH=/usr/lib64/ceph/mgr

MON=3 OSD=3 MDS=3 ../src/vstart.sh -d -n

echo "Real (no dev) dashboard: http://localhost:$DASHBOARD_HOST_PORT/#/login"

exec sleep 3600000
