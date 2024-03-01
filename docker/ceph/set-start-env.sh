#!/bin/bash

set -e

source /docker/set-mstart-env.sh

[[ -z "$MGR" ]] && export MGR=1
[[ -z "$MGR_PYTHON_PATH" ]] && export MGR_PYTHON_PATH=/ceph/src/pybind/mgr
[[ -d "$MGR_PYTHON_PATH"/dashboard/frontend ]] && export IS_UPSTREAM_LUMINOUS=0
[[ -z "$RGW" ]] && export RGW=1

export IS_FIRST_CLUSTER=$(hostname | grep -v cluster | wc -l)

[[ ("$IS_CEPH_RPM" == 0 || -n "$CEPH_REPO_DIR") && "$IS_UPSTREAM_LUMINOUS" == 0 && "$IS_FIRST_CLUSTER" == 1 ]] \
    && export FRONTEND_BUILD_REQUIRED=1
FRONTEND_BUILD_OPTIONS=${FRONTEND_BUILD_OPTIONS:-"--deleteOutputPath=false"}

if [[ "$RGW_MULTISITE" == 1 ]]; then
    export RGW=0  # Required to prevent vstart from starting any rgw daemon.

    if [[ "$IS_FIRST_CLUSTER" == 0 ]]; then
        export FS=0
        export MDS=0
        export MGR=0
        export MON=1
    fi
fi

RGW_DEBUG=''
VSTART_OPTIONS='-n'
if [[ "$CEPH_DEBUG" == 1 ]]; then
    RGW_DEBUG='--debug-rgw=20 --debug-ms=1'
    VSTART_OPTIONS="$VSTART_OPTIONS -d"
fi
export RGW_DEBUG
export VSTART_OPTIONS

HTTP_PROTO='http'
if [[ "$DASHBOARD_SSL" == 1 ]]; then
    HTTP_PROTO='https'
fi
export HTTP_PROTO
export CEPH_MGR_DASHBOARD_PORT=$(($CEPH_PORT + 1000))
