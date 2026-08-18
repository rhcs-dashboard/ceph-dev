#!/bin/bash
set -e

BASE_DIRECTORY_FOR_OSDS="/var/lib/ceph/cephalobox-osds"
OSD_FILE_BACKING_SIZE="20G"
CEPH_INTERNAL_USER_ID="167"
CEPH_INTERNAL_GROUP_ID="167"

mkdir -p "$BASE_DIRECTORY_FOR_OSDS"

CONFIG_PATH="$BASE_DIRECTORY_FOR_OSDS/ceph.conf"
cephadm shell -- cat /etc/ceph/ceph.conf > "$CONFIG_PATH"

if [ -n "$CEPHADM_IMAGE" ] && [ "$CEPHADM_IMAGE" != "None" ]; then
    CONTAINER_IMAGE="$CEPHADM_IMAGE"
else
    echo "No CEPHADM_IMAGE specified. getting it from local podman images..."
    CONTAINER_IMAGE=$(podman images --format "{{.Repository}}:{{.Tag}}" | grep ceph | head -n 1)
fi

if [ -z "$CONTAINER_IMAGE" ]; then
    echo "[FATAL] No pre-cached Ceph image found!"
    exit 1
fi

for i in {0..2}
do
    echo -e "\n=== Phase 4.$i: Provisioning Standalone OSD ==="
    
    ASSIGNED_OSD_ID=$(cephadm shell -- ceph osd create)
    echo "[EXEC] Created OSD ID: $ASSIGNED_OSD_ID"
    
    OSD_SPECIFIC_DIRECTORY="$BASE_DIRECTORY_FOR_OSDS/osd-$ASSIGNED_OSD_ID"
    mkdir -p "$OSD_SPECIFIC_DIRECTORY"
    
    KEYRING_OUTPUT_PATH="$OSD_SPECIFIC_DIRECTORY/keyring"
    cephadm shell -- ceph auth get-or-create osd.$ASSIGNED_OSD_ID \
        mon 'allow profile osd' mgr 'allow profile osd' osd 'allow *' > "$KEYRING_OUTPUT_PATH"
    
    BLOCK_DEVICE_FILE_PATH="$OSD_SPECIFIC_DIRECTORY/block"
    truncate -s "$OSD_FILE_BACKING_SIZE" "$BLOCK_DEVICE_FILE_PATH"
    chown -R "$CEPH_INTERNAL_USER_ID":"$CEPH_INTERNAL_GROUP_ID" "$OSD_SPECIFIC_DIRECTORY"
    
    # format OSD using the image's built-in binary
    echo "[EXEC] Formatting OSD $ASSIGNED_OSD_ID with BlueStore..."
    podman run --rm --net=host \
        -v "$CONFIG_PATH":/etc/ceph/ceph.conf:z \
        -v "$OSD_SPECIFIC_DIRECTORY":/var/lib/ceph/osd/ceph-$ASSIGNED_OSD_ID:z \
        "$CONTAINER_IMAGE" ceph-osd -i "$ASSIGNED_OSD_ID" --mkfs
    
    # start OSD Daemon in background using the image's built-in binary
    echo "[EXEC] Starting background OSD container: cephalobox-osd-$ASSIGNED_OSD_ID"
    podman run -d --name cephalobox-osd-$ASSIGNED_OSD_ID --net=host \
        -v "$CONFIG_PATH":/etc/ceph/ceph.conf:z \
        -v "$OSD_SPECIFIC_DIRECTORY":/var/lib/ceph/osd/ceph-$ASSIGNED_OSD_ID:z \
        "$CONTAINER_IMAGE" ceph-osd -i "$ASSIGNED_OSD_ID" -f
done

echo -e "\n=== CephaloBox OSD Provisioning Complete! ==="
cephadm shell -- ceph -s
