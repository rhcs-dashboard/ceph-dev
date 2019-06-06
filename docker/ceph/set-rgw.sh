#!/bin/bash

set -e

readonly RGW_REALM_ADMIN_UID=dev
readonly RGW_REALM_ADMIN_NAME='Dev Admin'
readonly RGW_REALM_ADMIN_ACCESS_KEY=DiPt4V7WWvy2njL1z6aC
readonly RGW_REALM_ADMIN_SECRET_KEY=xSZUdYky0bTctAdCEEW8ikhfBVKsBV5LFYL82vvh

if [[ "$RGW_MULTISITE" == 1 ]]; then
    start_rgw_daemon() {
        "$CEPH_BIN"/radosgw --log-file="$CEPH_OUT_DIR"/radosgw.8000.log --admin-socket="$CEPH_OUT_DIR"/radosgw.8000.asok \
            --pid-file="$CEPH_OUT_DIR"/radosgw.8000.pid -n client.rgw --rgw_frontends="beast port=8000" ${RGW_DEBUG}
    }

    REALM=dev-realm
    MASTER_ZONEGROUP=master-zonegroup

    if [[ "$IS_FIRST_CLUSTER" == 1 ]]; then
        # Create default realm, its master zonegroup & its master zone:
        "$CEPH_BIN"/radosgw-admin realm create --rgw-realm "$REALM" \
            --default
        "$CEPH_BIN"/radosgw-admin zonegroup create --rgw-realm "$REALM" --rgw-zonegroup "$MASTER_ZONEGROUP" \
            --endpoints http://${HOSTNAME}:8000 \
            --master --default
        MASTER_ZONE=master-zone
        "$CEPH_BIN"/radosgw-admin zone create --rgw-zonegroup "$MASTER_ZONEGROUP" --rgw-zone "$MASTER_ZONE" \
            --endpoints http://$HOSTNAME:8000 --access-key $RGW_REALM_ADMIN_ACCESS_KEY --secret $RGW_REALM_ADMIN_SECRET_KEY \
            --master --default

        # Migrate single-site to multi-site:
        #"$CEPH_BIN"/radosgw-admin zonegroup rename --rgw-zonegroup default --zonegroup-new-name="$MASTER_ZONEGROUP"
        #"$CEPH_BIN"/radosgw-admin zone rename --rgw-zone default --zone-new-name "$MASTER_ZONE" --rgw-zonegroup="$MASTER_ZONEGROUP"
        #"$CEPH_BIN"/radosgw-admin zonegroup modify --rgw-realm="$REALM" --rgw-zonegroup="$MASTER_ZONEGROUP" \
        #    --endpoints http://${HOSTNAME}:8000 \
        #    --master --default
        #"$CEPH_BIN"/radosgw-admin zone modify --rgw-realm="$REALM" --rgw-zonegroup="$MASTER_ZONEGROUP" --rgw-zone="$MASTER_ZONE" \
        #    --endpoints http://${HOSTNAME}:8000 --access-key $RGW_REALM_ADMIN_ACCESS_KEY --secret $RGW_REALM_ADMIN_SECRET_KEY \
        #    --master --default

        # Add placement target(s):
        DEV_PLACEMENT_TARGET=dev-placement
        "$CEPH_BIN"/radosgw-admin zonegroup placement add --rgw-zonegroup "$MASTER_ZONEGROUP" \
            --placement-id "$DEV_PLACEMENT_TARGET"
        "$CEPH_BIN"/radosgw-admin zone placement add --rgw-zone "$MASTER_ZONE" \
            --placement-id "$DEV_PLACEMENT_TARGET" \
            --data-pool "$MASTER_ZONEGROUP".rgw.dev.data \
            --index-pool "$MASTER_ZONEGROUP".rgw.dev.index

        # Add storage class(es):
        if [[ "$CEPH_VERSION" -ge '14' ]]; then
            COLD_STORAGE_CLASS=COLD
            "$CEPH_BIN"/radosgw-admin zonegroup placement add --rgw-zonegroup "$MASTER_ZONEGROUP" \
                --placement-id "$DEV_PLACEMENT_TARGET" \
                --storage-class "$COLD_STORAGE_CLASS"
            "$CEPH_BIN"/radosgw-admin zone placement add --rgw-zone "$MASTER_ZONE" \
                --placement-id "$DEV_PLACEMENT_TARGET" \
                --storage-class "$COLD_STORAGE_CLASS" \
                --data-pool "$MASTER_ZONEGROUP".rgw.cold.data
        fi

        "$CEPH_BIN"/radosgw-admin period update --rgw-realm "$REALM" --commit

        # Create 2nd realm, its master zonegroup & its master zone:
        REALM_2=dev-realm2
        "$CEPH_BIN"/radosgw-admin realm create --rgw-realm "$REALM_2"
        REALM_2_ZONEGROUP="$REALM_2"-zonegroup
        "$CEPH_BIN"/radosgw-admin zonegroup create --rgw-realm "$REALM_2" --rgw-zonegroup "$REALM_2_ZONEGROUP" \
            --endpoints http://${HOSTNAME}:8000 \
            --master --default
        REALM_2_ZONE="$REALM_2"-zone
        "$CEPH_BIN"/radosgw-admin zone create --rgw-zonegroup "$REALM_2_ZONEGROUP" --rgw-zone "$REALM_2_ZONE" \
            --endpoints http://$HOSTNAME:8000 --access-key $RGW_REALM_ADMIN_ACCESS_KEY --secret $RGW_REALM_ADMIN_SECRET_KEY \
            --master --default
        "$CEPH_BIN"/radosgw-admin period update --rgw-realm "$REALM_2" --commit

        start_rgw_daemon
    else
        readonly FIRST_CLUSTER_HOSTNAME=$(hostname | sed -e 's/-cluster.//')
        readonly ZONE_2=zone-2
        readonly ARCHIVE_ZONE=archive-zone

        set_secondary_zones() {
            while true; do
                IS_FIRST_GATEWAY_AVAILABLE=$(curl -LsS http://${FIRST_CLUSTER_HOSTNAME}:8000 2>&1 | grep "xml version" | wc -l)
                if [[ $IS_FIRST_GATEWAY_AVAILABLE == 1 ]]; then
                    "$CEPH_BIN"/radosgw-admin realm pull --rgw-realm "$REALM" --url http://${FIRST_CLUSTER_HOSTNAME}:8000 \
                        --access-key $RGW_REALM_ADMIN_ACCESS_KEY --secret $RGW_REALM_ADMIN_SECRET_KEY \
                        --default
                    "$CEPH_BIN"/radosgw-admin period pull --url=http://${FIRST_CLUSTER_HOSTNAME}:8000 \
                        --access-key $RGW_REALM_ADMIN_ACCESS_KEY --secret $RGW_REALM_ADMIN_SECRET_KEY

                    # create secondary zone:
                    "$CEPH_BIN"/radosgw-admin zone create --rgw-zonegroup "$MASTER_ZONEGROUP" --rgw-zone "$ZONE_2" \
                        --endpoints http://$HOSTNAME:8000 --access-key $RGW_REALM_ADMIN_ACCESS_KEY \
                        --secret $RGW_REALM_ADMIN_SECRET_KEY

                    # create archive zone:
                    "$CEPH_BIN"/radosgw-admin zone create --rgw-zonegroup "$MASTER_ZONEGROUP" --rgw-zone "$ARCHIVE_ZONE" \
                        --endpoints http://$HOSTNAME:8000 --access-key $RGW_REALM_ADMIN_ACCESS_KEY \
                        --secret $RGW_REALM_ADMIN_SECRET_KEY \
                        --tier-type=archive

                    "$CEPH_BIN"/radosgw-admin period update --rgw-realm "$REALM" --commit

                    # Delete default zone & pools:
                    #"$CEPH_BIN"/radosgw-admin zone delete --rgw-zone=default
                    #"$CEPH_BIN"/ceph osd pool rm default.rgw.control default.rgw.control --yes-i-really-really-mean-it
                    #"$CEPH_BIN"/ceph osd pool rm default.rgw.log default.rgw.log --yes-i-really-really-mean-it
                    #"$CEPH_BIN"/ceph osd pool rm default.rgw.meta default.rgw.meta --yes-i-really-really-mean-it

                    start_rgw_daemon

                    break
                fi

                sleep 3
            done
        }
        set_secondary_zones
    fi
fi

if [[ "$IS_FIRST_CLUSTER" == 1 ]]; then
    "$CEPH_BIN"/radosgw-admin user create --uid "$RGW_REALM_ADMIN_UID" --display-name "$RGW_REALM_ADMIN_NAME" \
        --access-key "$RGW_REALM_ADMIN_ACCESS_KEY" --secret "$RGW_REALM_ADMIN_SECRET_KEY" --system

    "$CEPH_BIN"/ceph dashboard set-rgw-api-user-id "$RGW_REALM_ADMIN_UID"
    "$CEPH_BIN"/ceph dashboard set-rgw-api-access-key "$RGW_REALM_ADMIN_ACCESS_KEY"
    "$CEPH_BIN"/ceph dashboard set-rgw-api-secret-key "$RGW_REALM_ADMIN_SECRET_KEY"
fi
