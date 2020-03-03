#!/bin/bash

set -e

readonly RGW_REALM_ADMIN_UID='dev'
readonly RGW_REALM_ADMIN_NAME='Dev Admin'
readonly RGW_REALM_ADMIN_ACCESS_KEY='DiPt4V7WWvy2njL1z6aC'
readonly RGW_REALM_ADMIN_SECRET_KEY='xSZUdYky0bTctAdCEEW8ikhfBVKsBV5LFYL82vvh'
RGW_DAEMON_PORT=8000

add_placement_targets_and_storage_classes() {
    # Add placement targets:
    for PT_NUM in 1 2; do
        PT_NAME=pt"$PT_NUM"-"$ZONE_NAME"
        "$CEPH_BIN"/radosgw-admin zonegroup placement add --rgw-zonegroup "$ZONEGROUP_NAME" \
            --placement-id "$PT_NAME"

        "$CEPH_BIN"/radosgw-admin zone placement add --rgw-zonegroup "$ZONEGROUP_NAME" --rgw-zone "$ZONE_NAME" \
            --placement-id "$PT_NAME" \
            --data-pool "$PT_NAME".rgw.buckets.data \
            --index-pool "$PT_NAME".rgw.buckets.index
    done

    # Add cold storage class:
    if [[ "$CEPH_VERSION" -ge '14' ]]; then
        COLD_STORAGE_CLASS=COLD
        "$CEPH_BIN"/radosgw-admin zonegroup placement add --rgw-zonegroup "$ZONEGROUP_NAME" \
            --placement-id "$PT_NAME" \
            --storage-class "$COLD_STORAGE_CLASS"

        "$CEPH_BIN"/radosgw-admin zone placement add --rgw-zonegroup "$ZONEGROUP_NAME" --rgw-zone "$ZONE_NAME" \
            --placement-id "$PT_NAME" \
            --storage-class "$COLD_STORAGE_CLASS" \
            --data-pool "$PT_NAME".rgw.cold.data
    fi
}

create_system_user() {
    "$CEPH_BIN"/radosgw-admin user create --uid "$RGW_REALM_ADMIN_UID" --display-name "$RGW_REALM_ADMIN_NAME" \
        --access-key "$RGW_REALM_ADMIN_ACCESS_KEY" --secret "$RGW_REALM_ADMIN_SECRET_KEY" --system
}

start_rgw_daemon() {
    local RGW_DAEMON_PORT=$1
    local RGW_DAEMON_ZONEGROUP=$2
    local RGW_DAEMON_ZONE=$3
    local RGW_DAEMON_PID_FILE="$CEPH_OUT_DIR"/radosgw."$RGW_DAEMON_PORT".pid
    local RGW_DAEMON_NAME="client.rgw.$RGW_DAEMON_PORT"

    rm -f "$RGW_DAEMON_PID_FILE"

    if [[ $(grep "\[$RGW_DAEMON_NAME\]" "$CEPH_CONF" | grep -v grep | wc -l) == 0 ]]; then
        "$CEPH_BIN"/ceph -c "$CEPH_CONF" auth get-or-create "$RGW_DAEMON_NAME" \
            mon 'allow rw' osd 'allow rwx' mgr 'allow rw' \
            >> "$CEPH_CONF_PATH"/keyring
    fi

    "$CEPH_BIN"/radosgw -c "$CEPH_CONF" \
        --log-file="$CEPH_OUT_DIR"/radosgw."$RGW_DAEMON_PORT".log \
        --admin-socket="$CEPH_OUT_DIR"/radosgw."$RGW_DAEMON_PORT".asok \
        --pid-file="$RGW_DAEMON_PID_FILE" --rgw_frontends="beast port=$RGW_DAEMON_PORT" \
        -n "$RGW_DAEMON_NAME" ${RGW_DEBUG} \
        --rgw-region "${RGW_DAEMON_ZONEGROUP}" --rgw-zone "${RGW_DAEMON_ZONE}"
}

if [[ "$RGW_MULTISITE" == 1 ]]; then
    "$CEPH_BIN"/ceph config set global mon_max_pg_per_osd 800

    readonly REALM_NAME_PREFIX=realm
    readonly ZONEGROUP_NAME_PREFIX=zg
    readonly ZONE_NAME_PREFIX=zone
    if [[ "$IS_FIRST_CLUSTER" == 1 ]]; then
        # Add realms:
        for REALM_NUM in 1 2; do
            REALM_NAME="${REALM_NAME_PREFIX}${REALM_NUM}"
            REALM_OPTIONS=''
            [[ "$REALM_NUM" == 1 ]] && REALM_OPTIONS='--default'
            "$CEPH_BIN"/radosgw-admin realm create --rgw-realm "$REALM_NAME" ${REALM_OPTIONS}

            # Add zonegroups:
            for ZONEGROUP_NUM in 1 2; do
                ZONEGROUP_NAME="${ZONEGROUP_NAME_PREFIX}${ZONEGROUP_NUM}-${REALM_NAME}"
                ZONEGROUP_OPTIONS=''
                if [[ "$ZONEGROUP_NUM" == 1 ]]; then
                    ZONEGROUP_OPTIONS='--master --default'
                    RGW_DAEMON_ZONEGROUP_OPTION="$ZONEGROUP_NAME"
                    RGW_DAEMON_ZONEGROUP_PORT="${RGW_DAEMON_PORT}"
                fi
                "$CEPH_BIN"/radosgw-admin zonegroup create --rgw-realm "$REALM_NAME" --rgw-zonegroup "$ZONEGROUP_NAME" \
                    --endpoints http://${HOSTNAME}:"$RGW_DAEMON_PORT" ${ZONEGROUP_OPTIONS}

                # Add zones:
                for ZONE_NUM in 1 2; do
                    ZONE_NAME="${ZONE_NAME_PREFIX}${ZONE_NUM}-${ZONEGROUP_NAME}"
                    ZONE_OPTIONS=''
                    if [[ "$ZONE_NUM" == 1 && "$ZONEGROUP_NUM" == 1 ]]; then
                        ZONE_OPTIONS='--master --default'
                        RGW_DAEMON_ZONE_OPTION="$ZONE_NAME"
                    fi
                    "$CEPH_BIN"/radosgw-admin zone create --rgw-zonegroup "$ZONEGROUP_NAME" --rgw-zone "$ZONE_NAME" \
                        --endpoints http://$HOSTNAME:"$RGW_DAEMON_PORT" --access-key "$RGW_REALM_ADMIN_ACCESS_KEY" \
                        --secret "$RGW_REALM_ADMIN_SECRET_KEY" ${ZONE_OPTIONS}

                    [[ "$REALM_NUM" == 1 && "$ZONEGROUP_NUM" == 1 && "$ZONE_NUM" == 1 ]] && create_system_user

                    add_placement_targets_and_storage_classes
                done

                RGW_DAEMON_PORT=$((${RGW_DAEMON_PORT} + 1))
            done

            "$CEPH_BIN"/radosgw-admin period update --rgw-realm "$REALM_NAME" --commit

            start_rgw_daemon "${RGW_DAEMON_ZONEGROUP_PORT}" "${RGW_DAEMON_ZONEGROUP_OPTION}" "${RGW_DAEMON_ZONE_OPTION}"
        done
    else
        readonly FIRST_CLUSTER_HOSTNAME=$(hostname | sed -e 's/-cluster.//')
        readonly CLUSTER2_PULL_REALM="${REALM_NAME_PREFIX}1"
        readonly CLUSTER2_ZONEGROUP="${ZONEGROUP_NAME_PREFIX}1-${CLUSTER2_PULL_REALM}"
        readonly CLUSTER2_ZONE="${ZONE_NAME_PREFIX}3-${CLUSTER2_ZONEGROUP}"
        readonly CLUSTER2_ARCHIVE_ZONE="${ZONE_NAME_PREFIX}4-${CLUSTER2_ZONEGROUP}"

        set_secondary_zones() {
            while true; do
                IS_FIRST_GATEWAY_AVAILABLE=$(curl -LsS http://${FIRST_CLUSTER_HOSTNAME}:"$RGW_DAEMON_PORT" 2>&1 | grep "xml version" | wc -l)
                if [[ $IS_FIRST_GATEWAY_AVAILABLE == 1 ]]; then
                    "$CEPH_BIN"/radosgw-admin realm pull --rgw-realm "$CLUSTER2_PULL_REALM" --url http://${FIRST_CLUSTER_HOSTNAME}:"$RGW_DAEMON_PORT" \
                        --access-key "$RGW_REALM_ADMIN_ACCESS_KEY" --secret "$RGW_REALM_ADMIN_SECRET_KEY" \
                        --default
                    "$CEPH_BIN"/radosgw-admin period pull --url=http://${FIRST_CLUSTER_HOSTNAME}:"$RGW_DAEMON_PORT" \
                        --access-key "$RGW_REALM_ADMIN_ACCESS_KEY" --secret "$RGW_REALM_ADMIN_SECRET_KEY"

                    # Add secondary zone:
                    "$CEPH_BIN"/radosgw-admin zone create --rgw-zonegroup "$CLUSTER2_ZONEGROUP" --rgw-zone "$CLUSTER2_ZONE" \
                        --endpoints http://$HOSTNAME:"$RGW_DAEMON_PORT" --access-key "$RGW_REALM_ADMIN_ACCESS_KEY" \
                        --secret "$RGW_REALM_ADMIN_SECRET_KEY"

                    # Add archive zone:
                    "$CEPH_BIN"/radosgw-admin zone create --rgw-zonegroup "$CLUSTER2_ZONEGROUP" --rgw-zone "$CLUSTER2_ARCHIVE_ZONE" \
                        --endpoints http://$HOSTNAME:"$RGW_DAEMON_PORT" --access-key "$RGW_REALM_ADMIN_ACCESS_KEY" \
                        --secret "$RGW_REALM_ADMIN_SECRET_KEY" \
                        --tier-type=archive

                    "$CEPH_BIN"/radosgw-admin period update --rgw-realm "$CLUSTER2_PULL_REALM" --commit

                    start_rgw_daemon "$RGW_DAEMON_PORT" "${CLUSTER2_ZONEGROUP}" "${CLUSTER2_ZONE}"

                    break
                fi

                sleep 3
            done
        }
        set_secondary_zones
    fi
else
    ZONEGROUP_NAME=default
    ZONE_NAME=default
    add_placement_targets_and_storage_classes
    create_system_user
    pkill radosgw
    start_rgw_daemon "$RGW_DAEMON_PORT" "${ZONEGROUP_NAME}" "${ZONE_NAME}"
fi

if [[ "$IS_FIRST_CLUSTER" == 1 ]]; then
    # Create MFA TOTP token.
    "$CEPH_BIN"/radosgw-admin mfa create --uid="$RGW_REALM_ADMIN_UID" --totp-serial=1 --totp-seed=23456723 --totp-seed-type=base32
    if [[ "$RGW_MULTISITE" != 1 ]]; then
        "$CEPH_BIN"/radosgw-admin mfa create --uid=testid --totp-serial=1 --totp-seed=23456723 --totp-seed-type=base32
    fi

    "$CEPH_BIN"/ceph dashboard set-rgw-api-user-id "$RGW_REALM_ADMIN_UID"
    "$CEPH_BIN"/ceph dashboard set-rgw-api-access-key "$RGW_REALM_ADMIN_ACCESS_KEY"
    "$CEPH_BIN"/ceph dashboard set-rgw-api-secret-key "$RGW_REALM_ADMIN_SECRET_KEY"
fi

if [[ -f "/root/.aws/credentials" ]]; then
    echo "aws_access_key_id = $RGW_REALM_ADMIN_ACCESS_KEY
aws_secret_access_key = $RGW_REALM_ADMIN_SECRET_KEY" >> /root/.aws/credentials
fi
