#!/bin/bash -i

set -e

cd /ceph/build

MGR_ID=$("$CEPH_BIN"/ceph mgr stat | awk -v FS='"active_name": ' 'NF>1{print $2}' | tr -d '",')
"$CEPH_BIN"/ceph mgr fail "$MGR_ID"
