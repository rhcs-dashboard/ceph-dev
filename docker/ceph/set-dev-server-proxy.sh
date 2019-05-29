#!/bin/bash

set -e

readonly DASHBOARD_URL="\"$HTTP_PROTO://localhost:$CEPH_MGR_DASHBOARD_PORT\""

cd "$MGR_PYTHON_PATH"/dashboard/frontend

jq '.["/api/"].target'="$DASHBOARD_URL" proxy.conf.json.sample | jq '.["/ui-api/"].target'="$DASHBOARD_URL" > proxy.conf.json
