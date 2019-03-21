#!/bin/bash

set -e

echo 'Running "npm test"...'

cd /ceph/dev/src/pybind/mgr/dashboard/frontend

cp /docker/mimic/karma.conf.js .

. /ceph/venv/bin/activate

npm run test

deactivate_node
