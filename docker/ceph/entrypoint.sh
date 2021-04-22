#!/bin/bash

set -e

export_var() {
    export "${1?}"
    echo "export $1" >> /root/.bashrc
}

export_var IS_CEPH_RPM="$(command -v ceph-mgr 2>/dev/null | wc -l)"

# Env. vars used in vstart.
export_var CEPH_ASOK_DIR=/ceph/build."${HOSTNAME}"/out
export_var CEPH_CONF=/ceph/build."${HOSTNAME}"/ceph.conf
export_var CEPH_CONF_PATH=/ceph/build."${HOSTNAME}"
export_var CEPH_DEV_DIR=/ceph/build."${HOSTNAME}"/dev
export_var CEPH_OUT_DIR=/ceph/build."${HOSTNAME}"/out
export_var CEPH_PORT="${CEPH_PORT:-10000}"

rm -rf /ceph/build
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

    mkdir /ceph/build
    cp -rT /docker/rpm/build-fake /ceph/build
else
    # Ceph build mode.
    export_var CEPH_BIN=/ceph/build/bin

    readonly CUSTOM_BUILD_DIR=/ceph/build.custom
    readonly NODEENV_BIN_DIR=src/pybind/mgr/dashboard/node-env/bin
    
    if [[ -e "$CUSTOM_BUILD_DIR/$NODEENV_BIN_DIR" ]]; then
        ln -sT $CUSTOM_BUILD_DIR /ceph/build
        export_var CUSTOM_BUILD_DIR_ENABLED=1
    else
        ln -sT /ceph/build.latest /ceph/build
    fi
fi

# Common env. vars.
if [[ "${IS_CEPH_RPM}" == 1 ]]; then
    if [[ -z "$CEPH_VERSION" ]]; then
        export_var CEPH_VERSION="$("$CEPH_BIN"/ceph -v | cut -d" "  -f3 | cut -d. -f1)"
    elif [[ "$CEPH_VERSION" == 'De' ]]; then
        export_var CEPH_VERSION=1000000
    fi

    if [[ "$(rpm -qi ceph-mgr-dashboard | grep -c 'Red Hat')" -gt 0 ]]; then
        export_var IS_UPSTREAM=0
    else
        export_var IS_UPSTREAM=1
    fi
else
    # git describe returns "v17.0.0-3432-ga67d1cf2a7" but we only need "17"
    export_var CEPH_VERSION="$(git describe | cut -c2- | cut -d. -f1)"

    if [[ "$(git rev-parse --abbrev-ref HEAD)" == ceph-*-rhel-patches ]]; then
      export_var IS_UPSTREAM=0
    else
      export_var IS_UPSTREAM=1
    fi
fi

export_var NODE_OPTIONS=--max_old_space_size=4096

exec "$@"
