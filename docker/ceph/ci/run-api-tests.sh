#!/bin/bash

set -e

source /docker/ci/sanity-checks.sh

(time run_api_tests "$@") 2>&1 | tee api-tests.log
