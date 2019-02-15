#!/bin/bash

set -e

# Enable dashboard module in vstart:
echo '
ceph_SOURCE_DIR:STATIC=/ceph
WITH_MGR_DASHBOARD_FRONTEND:BOOL=ON
WITH_RBD:BOOL=ON
' > /ceph/build/CMakeCache.txt

# Create directory for vstart logs, ...
readonly VSTART_DEBUG_DIR=/ceph/debug/build/"$(hostname -s)"
rm -rf "$VSTART_DEBUG_DIR"
mkdir -p "$VSTART_DEBUG_DIR"

export CEPH_DEV_DIR="$VSTART_DEBUG_DIR"/dev
export CEPH_OUT_DIR="$VSTART_DEBUG_DIR"/out

/docker/start-ceph.sh

#/usr/bin/ceph -c /ceph/build/ceph.conf config-key set mgr/dashboard/ssl false
#/usr/bin/ceph -c /ceph/build/ceph.conf mgr module disable dashboard
#sleep 1
#/usr/bin/ceph -c /ceph/build/ceph.conf mgr module enable dashboard

# Avoid the need of using "-c" option when running ceph command from /ceph dir
cd /ceph
ln -sf /ceph/build/ceph.conf ceph.conf

# Keep container running
exec tail -f /dev/null
