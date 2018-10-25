#!/bin/bash

set -e

# Enable dashboard module in vstart:
echo '
ceph_SOURCE_DIR:STATIC=/ceph
WITH_MGR_DASHBOARD_FRONTEND:BOOL=ON
WITH_RBD:BOOL=ON
' > /ceph/build/CMakeCache.txt

# Create directory for vstart logs, ...
VSTART_DEBUG_DIR=/ceph/debug/build/rhcs3.2
rm -rf "$VSTART_DEBUG_DIR"
mkdir -p "$VSTART_DEBUG_DIR"

export CEPH_DEV_DIR="$VSTART_DEBUG_DIR"/dev
export CEPH_OUT_DIR="$VSTART_DEBUG_DIR"/out

/docker/start-ceph.sh

#/usr/bin/ceph -c /ceph/build/ceph.conf config-key set mgr/dashboard/ssl false
#/usr/bin/ceph -c /ceph/build/ceph.conf mgr module disable dashboard
#sleep 1
#/usr/bin/ceph -c /ceph/build/ceph.conf mgr module enable dashboard

exec /opt/node_exporter/node_exporter
