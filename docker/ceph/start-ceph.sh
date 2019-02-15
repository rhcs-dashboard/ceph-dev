#!/bin/bash

set -e

cd /ceph/build

rm -rf out dev

export CEPH_BIN="./bin"

# rpm installation configuration:
if [[ -e /usr/bin/ceph-mgr ]]; then
    export CEPH_BIN=/usr/bin
    export CEPH_LIB=/usr/lib64/ceph
    export CEPH_PORT=10000
    export EC_PATH="$CEPH_LIB"/erasure-code
    export MGR_PYTHON_PATH="$CEPH_LIB"/mgr
    export OBJCLASS_PATH=/usr/lib64/rados-classes

    ln -sf "$EC_PATH"/* "$CEPH_LIB"
    ln -sf "$OBJCLASS_PATH"/* "$CEPH_LIB"

#    function on_exit {
#        cat /ceph/build/ceph.conf
#    }
#    trap on_exit ERR
fi
if [[ -z "$MGR" ]]; then
    export MGR=1
fi
if [[ -z "$RGW" ]]; then
    export RGW=1
fi

../src/vstart.sh -d -n

echo 'vstart.sh completed!'

# Enable prometheus module
"$CEPH_BIN"/ceph -c /ceph/build/ceph.conf mgr module enable prometheus

if [[ "$(hostname -s)" == 'luminous' ]]; then
    exit 0
fi

# Enable the Object Gateway management frontend
"$CEPH_BIN"/radosgw-admin user create --uid=dev --display-name=Dev --system
"$CEPH_BIN"/ceph dashboard set-rgw-api-user-id dev
readonly ACCESS_KEY=$("$CEPH_BIN"/radosgw-admin user info --uid=dev | jq .keys[0].access_key | sed -e 's/^"//' -e 's/"$//')
readonly SECRET_KEY=$("$CEPH_BIN"/radosgw-admin user info --uid=dev | jq .keys[0].secret_key | sed -e 's/^"//' -e 's/"$//')
"$CEPH_BIN"/ceph dashboard set-rgw-api-access-key "$ACCESS_KEY"
"$CEPH_BIN"/ceph dashboard set-rgw-api-secret-key "$SECRET_KEY"

# Configure grafana
set_grafana_api_url() {
    while true; do
        GRAFANA_IP=$(getent ahosts grafana.dev | tail -1 | awk '{print $1}')
        if [[ -n "$GRAFANA_IP" ]]; then
            "$CEPH_BIN"/ceph dashboard set-grafana-api-url "http://$GRAFANA_IP:$GRAFANA_HOST_PORT"

            break
        fi

        sleep 3
    done
}
set_grafana_api_url &

# Configure alertmanager
set_alertmanager_api_host() {
    while true; do
        ALERTMANAGER_IP=$(getent ahosts alertmanager.dev | tail -1 | awk '{print $1}')
        if [[ -n "$ALERTMANAGER_IP" ]]; then
            "$CEPH_BIN"/ceph dashboard set-alertmanager-api-host "http://$ALERTMANAGER_IP:$ALERTMANAGER_HOST_PORT"

            break
        fi

        sleep 3
    done
}
set_alertmanager_api_host &

# Create dashboard "test" user:
"$CEPH_BIN"/ceph dashboard ac-user-create test test
