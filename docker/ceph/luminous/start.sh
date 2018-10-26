#!/bin/bash

set -e

export VSTART_DEBUG_DIR=/ceph/debug/build/luminous

exec /docker/rhcs/start-ceph.sh
