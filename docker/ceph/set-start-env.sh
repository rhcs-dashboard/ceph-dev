#!/bin/bash

set -e

[[ -z "$CEPH_VERSION" ]] && export CEPH_VERSION=$("$CEPH_BIN"/ceph -v | awk '{ print substr($3,1,2) }')
[[ -z "$MGR" ]] && export MGR=1
[[ -z "$MGR_PYTHON_PATH" ]] && export MGR_PYTHON_PATH=/ceph/src/pybind/mgr
[[ -d "$MGR_PYTHON_PATH"/dashboard/frontend ]] && export IS_UPSTREAM_LUMINOUS=0
[[ -z "$RGW" ]] && export RGW=1
