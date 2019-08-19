#!/bin/bash

set -e

source /docker/ci/sanity-checks.sh

run_tox "$@"
