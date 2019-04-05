#!/bin/bash

set -e

# Env. vars used in vstart
export CEPH_LIB=/usr/lib64/ceph
export EC_PATH="$CEPH_LIB"/erasure-code
export OBJCLASS_PATH=/usr/lib64/rados-classes

ln -sf "$EC_PATH"/* "$CEPH_LIB"
ln -sf "$OBJCLASS_PATH"/* "$CEPH_LIB"

# The dashboard is a separate noarch package since v14.1
export MGR_PYTHON_PATH=/usr/share/ceph/mgr
if [[ ! -d "$MGR_PYTHON_PATH" ]]; then
    export MGR_PYTHON_PATH="$CEPH_LIB"/mgr
fi

if [[ "$CEPH_RPM_DEV" == 'true' ]]; then
    export MGR_PYTHON_PATH="$CEPH_RPM_DEV_DIR"/src/pybind/mgr
    export PYTHONDONTWRITEBYTECODE=1
fi

exec "$@"
