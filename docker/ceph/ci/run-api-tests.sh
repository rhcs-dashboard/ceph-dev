#!/bin/bash

set -e

source /docker/ci/sanity-checks.sh

run_api_tests "$@"

echo 'API tests successfully finished! Congratulations!'
