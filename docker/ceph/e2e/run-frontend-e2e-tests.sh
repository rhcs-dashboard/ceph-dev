#!/bin/bash

set -e

cd /ceph/src/pybind/mgr/dashboard/frontend

npm install

npm run ng e2e -- --dev-server-target
