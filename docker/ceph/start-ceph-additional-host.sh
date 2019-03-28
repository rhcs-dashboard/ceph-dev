#!/bin/bash

set -e

cd /ceph/build

readonly OSD_UUID="$(uuidgen)"
readonly OSD_SECRET=$("$CEPH_BIN"/ceph-authtool --gen-print-key)

echo "{\"cephx_secret\": \"$OSD_SECRET\"}" > /tmp/"$OSD_UUID".json

readonly OSD_NUM=$("$CEPH_BIN"/ceph -k "$CEPH_CONF_PATH"/keyring osd new "$OSD_UUID" -i /tmp/"$OSD_UUID".json)

readonly OSD_DEV_DIR="$CEPH_DEV_DIR/osd$OSD_NUM"
rm -rf "$OSD_DEV_DIR" && mkdir "$OSD_DEV_DIR"

"$CEPH_BIN"/ceph-osd -i "$OSD_NUM" --mkfs --key "$OSD_SECRET" --osd-uuid "$OSD_UUID" --no-mon-config

echo "[osd.$OSD_NUM]
	key = $OSD_SECRET" > "$OSD_DEV_DIR"/keyring

"$CEPH_BIN"/ceph -k "$CEPH_CONF_PATH"/keyring -i "$OSD_DEV_DIR"/keyring auth add osd."$OSD_NUM" osd 'allow *' mon 'allow profile osd' mgr 'allow profile osd'

"$CEPH_BIN"/ceph-osd -i "$OSD_NUM"

exec tail -f /dev/null
