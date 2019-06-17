#!/bin/bash

set -e

echo 'Running Sanity checks...'

source /docker/ci/sanity-checks.sh

cd "$REPO_DIR"/src/pybind/mgr/dashboard/frontend

run_npm_ci
run_npm_lint
run_jest
run_npm_i18n
run_tox
run_mypy
run_api_tests
run_frontend_e2e_tests
run_build_doc

echo 'Sanity checks successfully finished! Congratulations!'
