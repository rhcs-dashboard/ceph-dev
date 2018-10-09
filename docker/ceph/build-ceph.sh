#!/bin/bash

set -e

CEPH_DIR=/ceph

cd $CEPH_DIR
./install-deps.sh

rm -rf $CEPH_DIR/build

# Tricks to improve CCACHE hit ratio
export SOURCE_DATE_EPOCH=358228200
export BUILD_DATE=$(date --utc --date=@${SOURCE_DATE_EPOCH} +%Y-%m-%d)
export CCACHE_SLOPPINESS="time_macros"
export ARGS='-D ENABLE_GIT_VERSION=OFF'

$CEPH_DIR/do_cmake.sh $ARGS


rm -rf $CEPH_DIR/src/pybind/mgr/dashboard/frontend/node_modules

cd $CEPH_DIR/build

make -j $(nproc --ignore=2)

echo "Ceph successfully built!!!"
