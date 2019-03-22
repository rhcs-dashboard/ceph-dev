#!/bin/bash

set -e

cd /ceph/build

readonly OSD_UUID="$(uuidgen)"
readonly OSD_SECRET=$("$CEPH_BIN"/ceph-authtool --gen-print-key)

echo "{\"cephx_secret\": \"$OSD_SECRET\"}" > /tmp/"$OSD_UUID".json

readonly OSD_NUM=$("$CEPH_BIN"/ceph -c /ceph/build/ceph.conf -k /ceph/build/keyring osd new "$OSD_UUID" -i /tmp/"$OSD_UUID".json)

#echo "[osd.$OSD_NUM]
#        host = $(hostname -s)" >> /ceph/build/ceph.conf

readonly OSD_DEV_DIR="/ceph/build/dev/osd$OSD_NUM"
rm -rf "$OSD_DEV_DIR" || true
mkdir "$OSD_DEV_DIR"

"$CEPH_BIN"/ceph-osd -i "$OSD_NUM" --mkfs --key "$OSD_SECRET" --osd-uuid "$OSD_UUID" --no-mon-config

echo "[osd.$OSD_NUM]
	key = $OSD_SECRET" > "$OSD_DEV_DIR"/keyring

"$CEPH_BIN"/ceph -c /ceph/build/ceph.conf -k /ceph/build/keyring -i "$OSD_DEV_DIR"/keyring auth add osd."$OSD_NUM" osd 'allow *' mon 'allow profile osd' mgr 'allow profile osd'

"$CEPH_BIN"/ceph-osd -i "$OSD_NUM" -c /ceph/build/ceph.conf

exec tail -f /dev/null
