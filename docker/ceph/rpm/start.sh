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

exec /docker/start.sh
