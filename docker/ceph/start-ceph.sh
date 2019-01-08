#!/bin/bash

set -e

cd /ceph/build

rm -rf out dev

export CEPH_BIN="./bin"

if [[ "$(yum list installed | grep ceph-mgr | wc -l)" == '1' ]]; then
    export CEPH_BIN=/usr/bin
    export CEPH_LIB=/usr/lib64
    export EC_PATH="$CEPH_LIB"/ceph/erasure-code
    export OBJCLASS_PATH="$CEPH_LIB"/rados-classes
    export MGR_PYTHON_PATH="$CEPH_LIB"/ceph/mgr
fi

MGR=1 RGW=1 ../src/vstart.sh -d -n

echo 'vstart.sh completed!'

# Enable prometheus module
"$CEPH_BIN"/ceph -c /ceph/build/ceph.conf mgr module enable prometheus

if [[ "$(hostname)" != 'luminous.dev' ]]; then
    # Enable the Object Gateway management frontend
    "$CEPH_BIN"/radosgw-admin user create --uid=dev --display-name=Dev --system
    "$CEPH_BIN"/ceph dashboard set-rgw-api-user-id dev
    readonly ACCESS_KEY=$("$CEPH_BIN"/radosgw-admin user info --uid=dev | jq .keys[0].access_key | sed -e 's/^"//' -e 's/"$//')
    readonly SECRET_KEY=$("$CEPH_BIN"/radosgw-admin user info --uid=dev | jq .keys[0].secret_key | sed -e 's/^"//' -e 's/"$//')
    "$CEPH_BIN"/ceph dashboard set-rgw-api-access-key "$ACCESS_KEY"
    "$CEPH_BIN"/ceph dashboard set-rgw-api-secret-key "$SECRET_KEY"

    # Configure grafana
    GRAFANA_IP=$(getent ahosts grafana.dev | tail -1 | awk '{print $1}')
    "$CEPH_BIN"/ceph dashboard set-grafana-api-url "http://$GRAFANA_IP:$GRAFANA_HOST_PORT"
fi
