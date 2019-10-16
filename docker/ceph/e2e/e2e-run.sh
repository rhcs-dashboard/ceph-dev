#!/usr/bin/env bash

set -eo pipefail

cd /ceph/src/pybind/mgr/dashboard/frontend

npm install

ARGS="--dev-server-target"
ANGULAR_VERSION=$(npm run ng version | grep 'Angular: ' | awk '{ print substr($2,1,1) }')
# In nautilus this flag is required because BASE_URL is not read in protractor config.
if [[ "$ANGULAR_VERSION" -le 7 ]]; then
    ARGS="$ARGS --baseUrl=${BASE_URL}"
fi

npm run e2e -- ${ARGS}

echo 'Frontend E2E tests successfully finished! Congratulations!'
