#!/bin/bash

set -e

source /docker/ci/sanity-checks.sh

TOX_ARGS="$@"

# Default behaviour: run unit tests
if [[ -z "$TOX_ARGS" ]]; then
    TOX_ARGS='py3-cov'
elif [[ "${1:0:6}" == 'tests/' ]]; then
    # Run user-defined unit tests
    TOX_ARGS="py3-run pytest $TOX_ARGS"
fi

run_tox "$TOX_ARGS"
