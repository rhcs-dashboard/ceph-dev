#!/bin/bash -i

set -e

cd /ceph/build

"$CEPH_BIN"/ceph dashboard sso disable
