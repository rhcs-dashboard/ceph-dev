#!/bin/bash

set -e

echo 'Running Sanity checks...'

source /docker/ci/sanity-checks.sh

cd "$REPO_DIR"/src/pybind/mgr/dashboard/frontend

npm install

run_npm_lint
run_jest
run_npm_i18n
run_tox

echo 'Sanity checks successfully finished! Congratulations!'
