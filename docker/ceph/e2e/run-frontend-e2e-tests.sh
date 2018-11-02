#!/bin/bash

set -e

cd /ceph/src/pybind/mgr/dashboard/frontend

npm install

npm run ng e2e -- --port 4201
