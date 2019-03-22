#!/bin/bash

set -e

cd /ceph/build

"$CEPH_BIN"/ceph dashboard sso disable
