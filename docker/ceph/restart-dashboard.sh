#!/bin/bash

set -e

cd /ceph/build

"$CEPH_BIN"/ceph mgr module disable dashboard
"$CEPH_BIN"/ceph mgr module enable dashboard --force
