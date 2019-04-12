#!/bin/bash

set -e

readonly RGW_REALM_ADMIN_UID=dev
readonly RGW_REALM_ADMIN_NAME='Dev Admin'
readonly RGW_REALM_ADMIN_ACCESS_KEY=DiPt4V7WWvy2njL1z6aC
readonly RGW_REALM_ADMIN_SECRET_KEY=xSZUdYky0bTctAdCEEW8ikhfBVKsBV5LFYL82vvh

if [[ "$RGW_MULTISITE" == 1 ]]; then
    pkill radosgw

    if [[ "$IS_FIRST_CLUSTER" == 1 ]]; then
        "$CEPH_BIN"/radosgw-admin realm create --rgw-realm dev-realm --default

        # Create zonegroup & zone:
        #"$CEPH_BIN"/radosgw-admin zonegroup create --rgw-zonegroup dev-zone-group --endpoints http://${HOSTNAME}:8000 --rgw-realm dev-realm --master --default
        #"$CEPH_BIN"/radosgw-admin zone create --rgw-zone dev-zone-1 --rgw-zonegroup dev-zone-group \
        #    --endpoints http://$HOSTNAME:8000 --access-key $RGW_REALM_ADMIN_ACCESS_KEY --secret $RGW_REALM_ADMIN_SECRET_KEY --master --default

        # Migrate single-site to multi-site:
        "$CEPH_BIN"/radosgw-admin zonegroup rename --rgw-zonegroup default --zonegroup-new-name=dev-zone-group
        "$CEPH_BIN"/radosgw-admin zone rename --rgw-zone default --zone-new-name dev-zone-1 --rgw-zonegroup=dev-zone-group
        "$CEPH_BIN"/radosgw-admin zonegroup modify --rgw-realm=dev-realm --rgw-zonegroup=dev-zone-group \
            --endpoints http://${HOSTNAME}:8000 --master --default
        "$CEPH_BIN"/radosgw-admin zone modify --rgw-realm=dev-realm --rgw-zonegroup=dev-zone-group --rgw-zone=dev-zone-1 \
            --endpoints http://${HOSTNAME}:8000 --access-key $RGW_REALM_ADMIN_ACCESS_KEY --secret $RGW_REALM_ADMIN_SECRET_KEY --master --default
    else
        readonly FIRST_CLUSTER_HOSTNAME=$(hostname | sed -e 's/-cluster.//')

        set_secondary_zone() {
            while true; do
                IS_FIRST_GATEWAY_AVAILABLE=$(curl -LsS http://${FIRST_CLUSTER_HOSTNAME}:8000 2>&1 | grep "xml version" | wc -l)
                if [[ $IS_FIRST_GATEWAY_AVAILABLE == 1 ]]; then
                    "$CEPH_BIN"/radosgw-admin realm pull --rgw-realm dev-realm --url http://${FIRST_CLUSTER_HOSTNAME}:8000 \
                        --access-key $RGW_REALM_ADMIN_ACCESS_KEY --secret $RGW_REALM_ADMIN_SECRET_KEY --default
                    "$CEPH_BIN"/radosgw-admin realm default --rgw-realm=dev-realm
                    "$CEPH_BIN"/radosgw-admin period pull --url=http://${FIRST_CLUSTER_HOSTNAME}:8000 \
                        --access-key $RGW_REALM_ADMIN_ACCESS_KEY --secret $RGW_REALM_ADMIN_SECRET_KEY

                    # create zone:
                    "$CEPH_BIN"/radosgw-admin zone create --rgw-zone dev-zone-2 --rgw-zonegroup dev-zone-group \
                        --endpoints http://$HOSTNAME:8000 --access-key $RGW_REALM_ADMIN_ACCESS_KEY \
                        --secret $RGW_REALM_ADMIN_SECRET_KEY

                    # Delete default zone & pools:
                    "$CEPH_BIN"/radosgw-admin zone delete --rgw-zone=default
                    "$CEPH_BIN"/ceph osd pool rm default.rgw.control default.rgw.control --yes-i-really-really-mean-it
                    "$CEPH_BIN"/ceph osd pool rm default.rgw.log default.rgw.log --yes-i-really-really-mean-it
                    "$CEPH_BIN"/ceph osd pool rm default.rgw.meta default.rgw.meta --yes-i-really-really-mean-it

                    break
                fi

                sleep 3
            done
        }
        set_secondary_zone
    fi

    "$CEPH_BIN"/radosgw-admin period update --commit
fi

if [[ "$IS_FIRST_CLUSTER" == 1 ]]; then
    "$CEPH_BIN"/radosgw-admin user create --uid "$RGW_REALM_ADMIN_UID" --display-name "$RGW_REALM_ADMIN_NAME" \
        --access-key "$RGW_REALM_ADMIN_ACCESS_KEY" --secret "$RGW_REALM_ADMIN_SECRET_KEY" --system

    "$CEPH_BIN"/ceph dashboard set-rgw-api-user-id "$RGW_REALM_ADMIN_UID"
    "$CEPH_BIN"/ceph dashboard set-rgw-api-access-key "$RGW_REALM_ADMIN_ACCESS_KEY"
    "$CEPH_BIN"/ceph dashboard set-rgw-api-secret-key "$RGW_REALM_ADMIN_SECRET_KEY"
fi

if [[ "$RGW_MULTISITE" == 1 ]]; then
    "$CEPH_BIN"/radosgw --log-file="$CEPH_OUT_DIR"/radosgw.8000.log --admin-socket="$CEPH_OUT_DIR"/radosgw.8000.asok \
        --pid-file="$CEPH_OUT_DIR"/radosgw.8000.pid --debug-rgw=20 --debug-ms=1 -n client.rgw --rgw_frontends="beast port=8000"
fi
