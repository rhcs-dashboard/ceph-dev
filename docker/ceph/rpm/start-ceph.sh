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

/docker/start-ceph.sh

#"$CEPH_BIN"/ceph config-key set mgr/dashboard/ssl false
#"$CEPH_BIN"/ceph mgr module disable dashboard
#sleep 1
#"$CEPH_BIN"/ceph mgr module enable dashboard

if [[ "$CEPH_RPM_DEV" == 'true' && -d "$MGR_PYTHON_PATH"/dashboard/frontend ]]; then
    cd "$MGR_PYTHON_PATH"/dashboard/frontend

    exec npm run build -- --watch
else
    # Keep container running
    exec tail -f /dev/null
fi
