#!/bin/bash

set -e

readonly DASHBOARD_URL="\"https://$(hostname):$(($CEPH_PORT + 1000))\""

cd /ceph/src/pybind/mgr/dashboard/frontend

jq '.["/api/"].target'="$DASHBOARD_URL" proxy.conf.json.sample | jq '.["/ui-api/"].target'="$DASHBOARD_URL" > proxy.conf.json
