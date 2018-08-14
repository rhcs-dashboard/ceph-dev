#!/bin/bash

set -e

readonly DASHBOARD_URL='"https://ceph.dev:11000"'

cd /ceph/src/pybind/mgr/dashboard/frontend

jq '.["/api/"].target'="$DASHBOARD_URL" proxy.conf.json.sample | jq '.["/ui-api/"].target'="$DASHBOARD_URL" > proxy.conf.json

npm install

exec npm run-script start
