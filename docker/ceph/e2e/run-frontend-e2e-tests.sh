#!/bin/bash

set -e

source /docker/ci/sanity-checks.sh

run_frontend_e2e_tests

echo 'Frontend E2E tests successfully finished! Congratulations!'
