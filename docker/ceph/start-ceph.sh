#!/bin/bash

set -e

cd /ceph/build

rm -rf out dev

RGW=1 CEPH_PORT=10000 ../src/vstart.sh -d -n

# Enable the Object Gateway management frontend
./bin/radosgw-admin user create --uid=dev --display-name=Dev --system
./bin/ceph dashboard set-rgw-api-user-id dev
readonly ACCESS_KEY=$(./bin/radosgw-admin user info --uid=dev | jq .keys[0].access_key | sed -e 's/^"//' -e 's/"$//')
readonly SECRET_KEY=$(./bin/radosgw-admin user info --uid=dev | jq .keys[0].secret_key | sed -e 's/^"//' -e 's/"$//')
./bin/ceph dashboard set-rgw-api-access-key "$ACCESS_KEY"
./bin/ceph dashboard set-rgw-api-secret-key "$SECRET_KEY"

# Enable prometheus module
./bin/ceph mgr module enable prometheus

# Configure grafana
./bin/ceph dashboard set-grafana-api-url 'http://grafana.dev:3000'
./bin/ceph dashboard set-grafana-api-auth-method 'password'
