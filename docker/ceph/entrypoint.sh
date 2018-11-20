#!/bin/bash

set -e

if [[ -e /build/CMakeCache.txt ]]; then
    mkdir -p /ceph/build
    mount -o bind /build /ceph/build
fi

exec "$@"
