#!/bin/bash

set -e

/docker/set-web-server-proxy.sh

cd /ceph/src/pybind/mgr/dashboard/frontend

npm install

exec npm run start
