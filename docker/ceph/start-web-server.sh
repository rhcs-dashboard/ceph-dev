#!/bin/bash

set -e

/docker/set-web-server-proxy.sh

cd /ceph/src/pybind/mgr/dashboard/frontend

exec npm run start
