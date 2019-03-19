#!/bin/bash

set -e

# Enable dashboard module in vstart:
echo '
ceph_SOURCE_DIR:STATIC=/ceph
WITH_MGR_DASHBOARD_FRONTEND:BOOL=ON
WITH_RBD:BOOL=ON
' > /ceph/build/CMakeCache.txt

# Create directory for vstart logs, ...
readonly CEPH_RPM_DEV_DIR=/ceph/dev
readonly VSTART_DEBUG_DIR="$CEPH_RPM_DEV_DIR"/build/"$(hostname -s)"
rm -rf "$VSTART_DEBUG_DIR"
mkdir -p "$VSTART_DEBUG_DIR"

export CEPH_DEV_DIR="$VSTART_DEBUG_DIR"/dev
export CEPH_OUT_DIR="$VSTART_DEBUG_DIR"/out

if [[ "$CEPH_RPM_DEV" == 'true' ]]; then
    export MGR_PYTHON_PATH="$CEPH_RPM_DEV_DIR"/src/pybind/mgr
    export PYTHONDONTWRITEBYTECODE=1

    . venv/bin/activate
    cd "$MGR_PYTHON_PATH"/dashboard/frontend

    if [[ "$(hostname -s)" == 'mimic' ]]; then
        rm -rf package-lock.json node_modules/@angular/cli
        npm update @angular/cli
    fi

    npm install -f
    npm run build
    deactivate_node

    ln -sf /ceph/dev/src/vstart.sh /ceph/src/vstart.sh
fi

/docker/start-ceph.sh

#/usr/bin/ceph -c /ceph/build/ceph.conf config-key set mgr/dashboard/ssl false
#/usr/bin/ceph -c /ceph/build/ceph.conf mgr module disable dashboard
#sleep 1
#/usr/bin/ceph -c /ceph/build/ceph.conf mgr module enable dashboard

# Avoid the need of using "-c" option when running ceph command from /ceph dir
cd /ceph
ln -sf /ceph/build/ceph.conf ceph.conf

if [[ "$CEPH_RPM_DEV" == 'true' ]]; then
    . venv/bin/activate
    cd "$MGR_PYTHON_PATH"/dashboard/frontend
    exec npm run build -- --watch
else
    # Keep container running
    exec tail -f /dev/null
fi
