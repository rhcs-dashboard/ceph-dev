#!/bin/sh

echo "Target image requested: $CEPHADM_TARGET_IMAGE_REFERENCE"

case "$CEPHADM_TARGET_IMAGE_REFERENCE" in
    "quay.ceph.io/ceph-ci/ceph:main" | \
    "quay.ceph.io/ceph-ci/ceph:umbrella" | \
    "quay.ceph.io/ceph-ci/ceph:tentacle")
        echo "[SKIP] $CEPHADM_TARGET_IMAGE_REFERENCE is a pre-bundled default."
        echo "[SKIP] Cephalobox already has this internally. Shutting down sidecar."
        exit 0
        ;;
esac

# if registry, then login
if [ -n "$REGISTRY_URL" ] && [ -n "$REGISTRY_USERNAME" ] && [ -n "$REGISTRY_PASSWORD" ]; then
    echo "[NETWORK] Logging into registry $REGISTRY_URL..."
    docker login "$REGISTRY_URL" -u "$REGISTRY_USERNAME" -p "$REGISTRY_PASSWORD"
fi

echo "[NETWORK] Custom image detected. Pulling via host..."
docker pull "$CEPHADM_TARGET_IMAGE_REFERENCE"

echo "[DISK] Generating offline tarball archive at /opt/ceph-image.tar..."
docker save "$CEPHADM_TARGET_IMAGE_REFERENCE" -o /opt/ceph-image.tar

echo "Custom image puller routine completed successfully."
