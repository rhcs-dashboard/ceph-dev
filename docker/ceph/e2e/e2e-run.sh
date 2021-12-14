#!/usr/bin/env bash

set -eo pipefail

cd /ceph/src/pybind/mgr/dashboard/frontend

export NODE_OPTIONS=--max_old_space_size=4096
if [[ "${RUN_NPM_INSTALL}" != 0 ]]; then
    npm ci
fi

npx webdriver-manager update --versions.chrome=$(google-chrome --version | awk '{ print $3 }')

ARGS="--dev-server-target --webdriverUpdate=false"
ANGULAR_VERSION=$(npm run ng version | grep 'Angular: ' | awk '{ print substr($2,1,1) }')
# In nautilus this flag is required because BASE_URL is not read in protractor config.
if [[ "$ANGULAR_VERSION" -le 7 ]]; then
    ARGS="$ARGS --baseUrl=${DASHBOARD_URL}"
fi

npm run e2e -- ${ARGS}

echo 'Frontend E2E tests successfully finished! Congratulations!'
