#!/bin/bash

set -e

export_var() {
    export "${1?}"
    echo "export $1" >> /root/.bashrc
}

echo $NUMBER_OF_CLUSTERS
declare -a CEPH_BIN_LIST
declare -a CEPH_CLUSTERS
for (( cluster=1; cluster<=$NUMBER_OF_CLUSTERS; cluster++ )); do
    CEPH_CLUSTERS[cluster]="CEPH${cluster}"
    CEPH_BIN_LIST[cluster]=${CEPH_CLUSTERS[cluster]}
    echo ${CEPH_CLUSTERS[cluster]}
    export_var ${CEPH_BIN_LIST[cluster]}="/ceph/src/mrun ${CEPH_CLUSTERS[cluster]} ceph"
done

CEPH_CLI() {
    export_var CEPH_CONF_PATH=/ceph/build.ceph-dev/run/CEPH1/
    /ceph/src/mrun CEPH1 ceph "$@"
}

CEPH2_CLI() {
    export_var CEPH_CONF_PATH=/ceph/build.ceph-dev/run/CEPH2/
    /ceph/src/mrun CEPH2 ceph "$@"
}

CEPH_CLI_ALL() {
    for cluster in ${CEPH_BIN_LIST[@]}; do
        export_var CEPH_BIN=/usr/bin/
        export_var BUILD_DIR=/ceph/build.ceph-dev/
        export_var CEPH_CONF_PATH=/ceph/build.ceph-dev/run/"${cluster}/"

        cd /ceph/build.ceph-dev
        ${!cluster} $@
    done
}
