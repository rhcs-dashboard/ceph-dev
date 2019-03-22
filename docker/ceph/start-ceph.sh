#!/bin/bash

set -e

[[ -z "$CEPH_VERSION" ]] && export CEPH_VERSION=$("$CEPH_BIN"/ceph -v | awk '{ print substr($3,1,2) }')
[[ -z "$MGR" ]] && export MGR=1
[[ -z "$MGR_PYTHON_PATH" ]] && export MGR_PYTHON_PATH=/ceph/src/pybind/mgr
[[ -z "$RGW" ]] && export RGW=1

# Build frontend ('dist' dir required by dashboard module):
if [[ (-z "$CEPH_RPM_DEV" || "$CEPH_RPM_DEV" == 'true') && -d "$MGR_PYTHON_PATH"/dashboard/frontend ]]; then
    cd "$MGR_PYTHON_PATH"/dashboard/frontend

    run_npm_build() {
        if [[ "$CEPH_VERSION" == '13' ]]; then
            rm -rf package-lock.json node_modules/@angular/cli
            npm update @angular/cli
        fi

        npm install -f
        npm run build
    }

    run_npm_build || (rm -rf node_modules && run_npm_build)
fi

cd /ceph/build

rm -rf out dev

../src/vstart.sh -d -n

echo 'vstart.sh completed!'

# Enable prometheus module
"$CEPH_BIN"/ceph -c /ceph/build/ceph.conf mgr module enable prometheus

# Upstream luminous start ends here
if [[ ! -d "$MGR_PYTHON_PATH"/dashboard/frontend ]]; then
    exit 0
fi

# Enable the Object Gateway management frontend
"$CEPH_BIN"/radosgw-admin user create --uid=dev --display-name=Dev --system
"$CEPH_BIN"/ceph dashboard set-rgw-api-user-id dev
readonly ACCESS_KEY=$("$CEPH_BIN"/radosgw-admin user info --uid=dev | jq .keys[0].access_key | sed -e 's/^"//' -e 's/"$//')
readonly SECRET_KEY=$("$CEPH_BIN"/radosgw-admin user info --uid=dev | jq .keys[0].secret_key | sed -e 's/^"//' -e 's/"$//')
"$CEPH_BIN"/ceph dashboard set-rgw-api-access-key "$ACCESS_KEY"
"$CEPH_BIN"/ceph dashboard set-rgw-api-secret-key "$SECRET_KEY"

# Upstream mimic start ends here
if [[ "$CEPH_VERSION" == '13' ]]; then
    exit 0
fi

# Create dashboard "test" user:
"$CEPH_BIN"/ceph dashboard ac-user-create test test

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

# RHCS 3.2 beta start ends here
if [[ "$CEPH_VERSION" -le '13' ]]; then
    exit 0
fi

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
