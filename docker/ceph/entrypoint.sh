#!/bin/bash

set -e

export_var() {
    export "$1"
    echo "export $1" >> /root/.bashrc
}

export_var IS_CEPH_RPM=$(which ceph-mgr 2>/dev/null | wc -l)

# Env. vars used in vstart.
export_var CEPH_ASOK_DIR=/ceph/build."${HOSTNAME}"/out
export_var CEPH_CONF=/ceph/build."${HOSTNAME}"/ceph.conf
export_var CEPH_CONF_PATH=/ceph/build."${HOSTNAME}"
export_var CEPH_DEV_DIR=/ceph/build."${HOSTNAME}"/dev
export_var CEPH_OUT_DIR=/ceph/build."${HOSTNAME}"/out
export_var CEPH_PORT=${CEPH_PORT:-10000}

mkdir -p "${CEPH_CONF_PATH}"

if [[ "${IS_CEPH_RPM}" == 1 ]]; then
    export_var CEPH_BIN=/usr/bin
    export_var CEPH_LIB=/usr/lib64/ceph
    export_var EC_PATH="$CEPH_LIB"/erasure-code
    export_var OBJCLASS_PATH=/usr/lib64/rados-classes
    
    ln -sf "$EC_PATH"/* "$CEPH_LIB"
    ln -sf "$OBJCLASS_PATH"/* "$CEPH_LIB"
    
    if [[ -z "$CEPH_REPO_DIR" ]]; then
        # The dashboard is a separate noarch package since v14.1
        export_var MGR_PYTHON_PATH=/usr/share/ceph/mgr
        if [[ ! -d "$MGR_PYTHON_PATH" ]]; then
            export_var MGR_PYTHON_PATH="$CEPH_LIB"/mgr
        fi
    fi

    # Set cmake vars checked by vstart (enable dashboard module, ...).
    mkdir -p /opt/ceph/build
    mkdir -p /ceph/build
    mount -o bind /opt/ceph/build /ceph/build
    echo '
ceph_SOURCE_DIR:STATIC=/ceph
WITH_MGR_DASHBOARD_FRONTEND:BOOL=ON
WITH_RBD:BOOL=ON
' > /ceph/build/CMakeCache.txt
else
    # Ceph build mode.
    export_var CEPH_BIN=/ceph/build/bin

    readonly BUILD_DIR=/ceph/build
    readonly CUSTOM_BUILD_DIR=/build
    readonly NODEENV_BIN_DIR=src/pybind/mgr/dashboard/node-env/bin
    
    if [[ -e "$CUSTOM_BUILD_DIR/$NODEENV_BIN_DIR" ]]; then
        mkdir -p $BUILD_DIR
        mount -o bind $CUSTOM_BUILD_DIR $BUILD_DIR
    
        export_var CUSTOM_BUILD_DIR_ENABLED=1
    fi
fi

# Common env. vars.
[[ -z "$CEPH_VERSION" ]] && export_var CEPH_VERSION=$("$CEPH_BIN"/ceph -v | awk '{ print substr($3,1,2) }')
[[ "$CEPH_VERSION" == 'De' ]] && export_var CEPH_VERSION=1000000
[[ -z "$CEPH_PATCH_VERSION" ]] && export_var CEPH_PATCH_VERSION=$("$CEPH_BIN"/ceph -v | sed -r 's/.*\.([0-9]*)\-.*/\1/')
[[ $(rpm -qi ceph-mgr-dashboard | grep 'Red Hat' | wc -l) > 0 ]] && export_var IS_UPSTREAM=0 || export_var IS_UPSTREAM=1
export_var NODE_OPTIONS=--max_old_space_size=4096

exec "$@"
