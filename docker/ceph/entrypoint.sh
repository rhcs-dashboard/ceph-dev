#!/bin/bash

set -e

readonly BUILD_DIR=/ceph/build
readonly CUSTOM_BUILD_DIR=/build
readonly NODEENV_BIN_DIR=src/pybind/mgr/dashboard/node-env/bin

ln -s "$BUILD_DIR/$NODEENV_BIN_DIR"/node /usr/bin/node \
    && ln -s "$BUILD_DIR/$NODEENV_BIN_DIR"/npm /usr/bin/npm \
    && ln -s "$BUILD_DIR/$NODEENV_BIN_DIR"/npx /usr/bin/npx

if [[ -e "$CUSTOM_BUILD_DIR/$NODEENV_BIN_DIR" ]]; then
    mkdir -p $BUILD_DIR
    mount -o bind $CUSTOM_BUILD_DIR $BUILD_DIR

    export CUSTOM_BUILD_DIR_ENABLED=1
fi

exec "$@"
