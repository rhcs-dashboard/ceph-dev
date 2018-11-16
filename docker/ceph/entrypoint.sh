#!/bin/bash

set -e

if [[ -e /build/CMakeCache.txt ]]; then
    mount -o bind /build /ceph/build
fi

exec "$@"
