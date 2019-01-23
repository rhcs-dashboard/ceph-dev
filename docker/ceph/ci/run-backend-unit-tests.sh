#!/bin/bash

set -e

source /docker/ci/sanity-checks.sh

if [[ -n "$@" ]]; then
    cd "$REPO_DIR"/src/pybind/mgr/dashboard

    TOX_ARGS='py3-run pytest '
    if [[ "$PYTHON_VERSION" != '3' ]]; then
        TOX_ARGS=${TOX_ARGS//3/27}
    fi
    TOX_ARGS+="$@"
fi

run_tox "$TOX_ARGS"
