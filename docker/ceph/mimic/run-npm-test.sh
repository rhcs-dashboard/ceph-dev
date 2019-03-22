#!/bin/bash

set -e

echo 'Running "npm test"...'

cd /ceph/dev/src/pybind/mgr/dashboard/frontend

cp /docker/mimic/karma.conf.js .

npm run test
