#!/bin/bash

set -e

source /docker/ci/sanity-checks.sh

if [[ -n "$@" ]]; then
    cd "$REPO_DIR"/src/pybind/mgr/dashboard

    readonly TOX_CONFIG_FILE=tox-run.ini
    cat tox.ini > "$TOX_CONFIG_FILE"
    echo '    run: {envbindir}/py.test {posargs}' >> "$TOX_CONFIG_FILE"

    ARGS="-e py27-run -c $TOX_CONFIG_FILE $@"
fi

run_tox "$ARGS"
