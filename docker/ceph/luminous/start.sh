#!/bin/bash

set -e

mkdir -p /ceph/build

cd /ceph/build

rm -rf out dev

if [[ "$LUMINOUS_START_FROM_RPM" == '1' ]]; then
    export CEPH_BIN=/usr/bin
    export CEPH_LIB=/usr/lib
    export EC_PATH=/usr/lib64/ceph/erasure-code
    export MGR_PYTHON_PATH=/usr/lib64/ceph/mgr
fi

export CEPH_PORT=10000

MON=3 OSD=3 MDS=3 ../src/vstart.sh -d -n

if [[ "$LUMINOUS_START_FROM_RPM" == '1' ]]; then
    echo "RPM dashboard: http://localhost:11000/#/login"

    exec sleep 3600000
else
    readonly DASHBOARD_URL='"https://luminous.dev:11000"'

    cd /ceph/src/pybind/mgr/dashboard/frontend

    jq '.["/api/"].target'="$DASHBOARD_URL" proxy.conf.json.sample | jq '.["/ui-api/"].target'="$DASHBOARD_URL" > proxy.conf.json

    npm install

    exec npm run-script start -- --host 0.0.0.0
fi
