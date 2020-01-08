#!/bin/bash

set -e

cd /ceph/src/pybind/mgr/dashboard/frontend

rm -rf dist

npm cache clean --force
npm install --no-shrinkwrap

cd /ceph/build

make mgr-dashboard-frontend-build
