#!/bin/bash

set -e

source /docker/ci/sanity-checks.sh

if [[ -n "$@" ]]; then
    cd "$REPO_DIR"/src/pybind/mgr/dashboard

    readonly TOX_CONFIG_FILE=tox.ini.tmp
    cat tox.ini > "$TOX_CONFIG_FILE"
    echo '    run: {envbindir}/py.test {posargs}' >> "$TOX_CONFIG_FILE"

    TOX_ARGS='-e py3-run'
    if [[ "$PYTHON_VERSION" != '3' ]]; then
        TOX_ARGS='-e py27-run'
    fi
    TOX_ARGS="$TOX_ARGS -c $TOX_CONFIG_FILE $@"
fi

run_tox "$TOX_ARGS"
