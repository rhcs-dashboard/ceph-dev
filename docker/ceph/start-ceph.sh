#!/bin/bash

set -e

source /docker/set-start-env.sh

# Build frontend:
if [[ "$FRONTEND_BUILD_REQUIRED" == 1 ]]; then
    cd "$MGR_PYTHON_PATH"/dashboard/frontend

    # Set dev server proxy:
    TARGET_URL="${HTTP_PROTO}://${HOSTNAME}:${CEPH_MGR_DASHBOARD_PORT}"
    [[ -n "${DASHBOARD_URL}" ]] && TARGET_URL=${DASHBOARD_URL}
    jq "(.[] | .target)=\""${TARGET_URL}"\"" proxy.conf.json.sample > proxy.conf.json

    if [[ "$CEPH_VERSION" == '13' ]]; then
        rm -rf package-lock.json node_modules/@angular/cli
        npm update @angular/cli
    fi

    if [[ "$DASHBOARD_NPM_CI" == 1 ]]; then
        npm ci
    else
        npm install
    fi

    if [[ -z "${DASHBOARD_URL}" && -z "${DOWNSTREAM_BUILD}" ]]; then
        # Required to run dashboard python module.
        npm run build
    fi

    # Start dev server
    if [[ "$DASHBOARD_DEV_SERVER" == 1 || -n "${DASHBOARD_URL}" ]]; then
        if [[ -n "$DOWNSTREAM_BUILD" ]]; then
            echo "Building downstream frontend for ${DOWNSTREAM_BUILD}..."
            npm run build -- --configuration=en-US,production-"${DOWNSTREAM_BUILD}" --output-path=dist
            npm run start -- --configuration=en-US,production-"${DOWNSTREAM_BUILD}" &
        else
            npm run start &
        fi

    elif [[ -z "${E2E_CMD}" ]]; then
        npm run build -- "${FRONTEND_BUILD_OPTIONS}" --watch &
    fi
fi

if [[ -n "${DASHBOARD_URL}" ]]; then
    [[ "$FRONTEND_BUILD_REQUIRED" != 1 ]] && echo 'ERROR: ceph repo not found.' && exit 1
    exit 0
fi

rm -rf "${CEPH_CONF_PATH:?}"/*

cd /ceph/build
../src/vstart.sh ${VSTART_OPTIONS}

echo 'vstart.sh completed!'

# Configure Object Gateway:
if [[ "$RGW" -gt 0  ||  "$RGW_MULTISITE" == 1 ]]; then
    /docker/set-rgw.sh
fi

# Enable prometheus module
"$CEPH_BIN"/ceph mgr module enable prometheus
echo 'Prometheus mgr module enabled.'

#Enable and set test_orchestrator module
if [[ "$TEST_ORCHESTRATOR" == 1 ]]; then
    /docker/scripts/mock-devices.sh
fi

# Upstream luminous start ends here
if [[ "$IS_UPSTREAM_LUMINOUS" != 0 ]]; then
    exit 0
fi

# Disable ssl (if selected)
readonly VSTART_HAS_SSL_FLAG=$(cat /ceph/src/vstart.sh | grep DASHBOARD_SSL | wc -l)
if [[ "$DASHBOARD_SSL" == 0 && "$VSTART_HAS_SSL_FLAG" == 0 ]]; then
    echo "Disabling SSL..."

    SSL_OPTIONS='--force'
    if [[ "$CEPH_VERSION" == 13 ]]; then
        SSL_OPTIONS=''
    fi

    "$CEPH_BIN"/ceph config set mgr mgr/dashboard/ssl false $SSL_OPTIONS
    "$CEPH_BIN"/ceph config set mgr mgr/dashboard/x/server_port "$CEPH_MGR_DASHBOARD_PORT" $SSL_OPTIONS
    /docker/restart-dashboard.sh

    echo "SSL disabled."
fi

# Secondary cluster start (or upstream mimic start) ends here.
[[ "$CEPH_VERSION" -le '13' ]] && exit 0

# Create dashboard "test" user:
[[ "$CEPH_VERSION" -gt '14' ]] && DASHBOARD_USER_CREATE_OPTIONS='--force-password'
create_test_user() {
    DASHBOARD_TEST_USER_SECRET_FILE="/tmp/dashboard-test-user-secret.txt"
    printf 'test' > "${DASHBOARD_TEST_USER_SECRET_FILE}"
    "$CEPH_BIN"/ceph dashboard ac-user-create test -i "${DASHBOARD_TEST_USER_SECRET_FILE}" "${DASHBOARD_USER_CREATE_OPTIONS}"
}
create_test_user || "$CEPH_BIN"/ceph dashboard ac-user-create test test "${DASHBOARD_USER_CREATE_OPTIONS}"

# Enable debug mode.
"$CEPH_BIN"/ceph dashboard debug enable

# Set monitoring stack:
/docker/set-monitoring.sh

# Upstream nautilus start ends here.
[[ "$CEPH_VERSION" -le '14' ]] && exit 0

# Set dashboard log level.
"$CEPH_BIN"/ceph config set mgr mgr/dashboard/log_level debug
