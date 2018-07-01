#!/bin/bash

set -e

cd /ceph/build

readonly DASHBOARD_URL=$(./bin/ceph mgr services | jq .dashboard)

cd /ceph/src/pybind/mgr/dashboard/frontend

jq '.["/api/"].target'=$DASHBOARD_URL proxy.conf.json.sample | jq '.["/ui-api/"].target'=$DASHBOARD_URL > proxy.conf.json

npm install

exec npm run-script start
