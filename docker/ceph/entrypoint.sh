#!/bin/bash

set -e

NODEENV_BIN_DIR=src/pybind/mgr/dashboard/node-env/bin

if [[ -e "/build/$NODEENV_BIN_DIR" ]]; then
    mkdir -p /ceph/build
    mount -o bind /build /ceph/build

    export CUSTOM_BUILD_DIR=1
fi

exec "$@"
