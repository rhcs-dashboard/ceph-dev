#!/bin/bash

set -e

#    function on_exit {
#        cat "$CEPH_CONF"
#    }
#    trap on_exit ERR

# Enable dashboard module in vstart:
echo '
ceph_SOURCE_DIR:STATIC=/ceph
WITH_MGR_DASHBOARD_FRONTEND:BOOL=ON
WITH_RBD:BOOL=ON
' > /ceph/build/CMakeCache.txt

if [[ "$CEPH_RPM_DEV" == 'true' ]]; then
    ln -sf /ceph/dev/src/vstart.sh /ceph/src/vstart.sh
fi

source /docker/set-start-env.sh
/docker/start-ceph.sh

# Disable ssl
readonly VSTART_HAS_SSL_FLAG=$(cat /ceph/src/vstart.sh | grep DASHBOARD_SSL | wc -l)
if [[ "$VSTART_HAS_SSL_FLAG" == 0 && "$IS_UPSTREAM_LUMINOUS" == 0 ]]; then
    echo "Disabling SSL..."

    "$CEPH_BIN"/ceph config set mgr mgr/dashboard/ssl false --force
    "$CEPH_BIN"/ceph config set mgr mgr/dashboard/x/server_port $(($CEPH_PORT + 1000)) --force
    /docker/restart-dashboard.sh

    echo "SSL disabled."
fi

if [[ "$CEPH_RPM_DEV" == 'true' && "$IS_UPSTREAM_LUMINOUS" == 0 ]]; then
    cd "$MGR_PYTHON_PATH"/dashboard/frontend

    exec npm run build -- --watch
else
    # Keep container running
    exec tail -f /dev/null
fi
