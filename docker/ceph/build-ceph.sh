#!/bin/bash

set -e

if [[ -n "$CUSTOM_BUILD_DIR_ENABLED" ]]; then
    echo 'ERROR: custom build directory not allowed for new build creation.'
    exit 1
fi

readonly CEPH_DIR=/ceph

cd $CEPH_DIR
./install-deps.sh

rm -rf $CEPH_DIR/build

readonly CCACHE_CONF_FILE="$HOME/.ccache/ccache.conf"
if [[ ! -f "$CCACHE_CONF_FILE" ]]; then
    echo 'max_size = 20G
sloppiness = file_macro,file_stat_matches,include_file_ctime,include_file_mtime,no_system_headers,pch_defines
' > "$CCACHE_CONF_FILE"
fi

$CEPH_DIR/do_cmake.sh -D ENABLE_GIT_VERSION=OFF

cd $CEPH_DIR/src/pybind/mgr/dashboard/frontend
rm -rf node_modules

cd $CEPH_DIR/build

make -j $(nproc --ignore=2) vstart mgr-dashboard-frontend-deps mgr-dashboard-frontend-build

echo "Ceph successfully built!!!"
