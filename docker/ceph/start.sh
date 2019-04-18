#!/bin/bash

set -e

source /docker/set-start-env.sh
/docker/start-ceph.sh

if [[ "$IS_UPSTREAM_LUMINOUS" == 0 && "$IS_FIRST_CLUSTER" == 1 ]]; then
    exec /docker/start-web-server.sh
else
    # Keep container running
    exec tail -f /dev/null
fi
