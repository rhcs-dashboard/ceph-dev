#!/bin/bash

set -e

# Build frontend ('dist' dir required by dashboard module):
if [[ (-z "$CEPH_RPM_DEV" || "$CEPH_RPM_DEV" == 1) && "$IS_UPSTREAM_LUMINOUS" == 0 && "$IS_FIRST_CLUSTER" == 1 ]]; then
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

rm -rf "$CEPH_CONF_PATH" && mkdir -p "$CEPH_CONF_PATH"

cd /ceph/build
../src/vstart.sh ${VSTART_OPTIONS}

echo 'vstart.sh completed!'

# Enable prometheus module
if [[ "$IS_FIRST_CLUSTER" == 1 ]]; then
    "$CEPH_BIN"/ceph mgr module enable prometheus
fi

# Upstream luminous start ends here
if [[ "$IS_UPSTREAM_LUMINOUS" != 0 ]]; then
    exit 0
fi

# Configure Object Gateway:
/docker/set-rgw.sh

# Upstream mimic start ends here
if [[ "$CEPH_VERSION" == '13' || "$IS_FIRST_CLUSTER" == 0 ]]; then
    exit 0
fi

# Create dashboard "test" user:
"$CEPH_BIN"/ceph dashboard ac-user-create test test

# Configure grafana
set_grafana_api_url() {
    while true; do
        GRAFANA_IP=$(getent ahosts grafana | tail -1 | awk '{print $1}')
        if [[ -n "$GRAFANA_IP" ]]; then
            "$CEPH_BIN"/ceph dashboard set-grafana-api-url "http://$GRAFANA_IP:$GRAFANA_HOST_PORT"

            break
        fi

        sleep 3
    done
}
set_grafana_api_url &

# RHCS 3.2 beta start ends here
if [[ "$CEPH_VERSION" == '12' ]]; then
    exit 0
fi

# Configure alertmanager
set_alertmanager_api_host() {
    while true; do
        ALERTMANAGER_IP=$(getent ahosts alertmanager | tail -1 | awk '{print $1}')
        if [[ -n "$ALERTMANAGER_IP" ]]; then
            "$CEPH_BIN"/ceph dashboard set-alertmanager-api-host "http://$ALERTMANAGER_IP:$ALERTMANAGER_HOST_PORT"

            break
        fi

        sleep 3
    done
}
set_alertmanager_api_host &
