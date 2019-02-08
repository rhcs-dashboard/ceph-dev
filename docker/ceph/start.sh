#!/bin/bash

set -e

# Build frontend ('dist' dir required by dashboard module):
cd /ceph/src/pybind/mgr/dashboard/frontend
npm install -f
npm run build

/docker/start-ceph.sh

exec /docker/start-web-server.sh
