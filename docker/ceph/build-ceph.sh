#!/bin/bash

set -e

if [[ "${IS_CEPH_RPM}" == 1 ]]; then
    echo 'ERROR: wrong image for building.'
    exit 1
elif [[ -n "$CUSTOM_BUILD_DIR_ENABLED" ]]; then
    echo 'ERROR: custom build directory not allowed for new build creation.'
    exit 1
fi

readonly CEPH_DIR=/ceph
cd $CEPH_DIR

# Clean-up
# ISSUE install-deps.sh can fail if submodule dirs contain stale data, so by --force'ing we wipe that out and avoid that error later
git submodule update --init --recursive --force
rm -rfd $CEPH_DIR/src/pybind/mgr/dashboard/frontend/node_modules
unlink $CEPH_DIR/build

# Settings to optimize CCache hit rate
export BUILD_DATE=1981-05-09
export SOURCE_DATE_EPOCH=358228200

readonly CCACHE_CONF_FILE="$HOME/.ccache/ccache.conf"
if [[ ! -f "$CCACHE_CONF_FILE" ]]; then
    echo 'max_size = 20G
sloppiness = file_macro,file_stat_matches,include_file_ctime,include_file_mtime,no_system_headers,pch_defines
' > "$CCACHE_CONF_FILE"
fi

# Build process
NPROC=$(nproc --ignore=2) $CEPH_DIR/src/script/run-make.sh \
  --cmake-args "-D ENABLE_GIT_VERSION=OFF" -- \
  --target vstart mgr-dashboard-frontend-deps mgr-dashboard-frontend-build

echo 'Renaming build as "build.latest"...'
cd $CEPH_DIR
mv -fT build build.latest

echo "Ceph successfully built!!!"
