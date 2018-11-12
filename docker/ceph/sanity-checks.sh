#!/bin/bash

set -e

readonly REPO_DIR="$PWD"

run_npm_lint() {
    echo 'Running "npm lint"...'

    cd "$REPO_DIR"/src/pybind/mgr/dashboard/frontend

    npm run lint
}

run_jest() {
    echo 'Running Jest...'

    cd "$REPO_DIR"/src/pybind/mgr/dashboard/frontend

    if [ ! -e 'src/unit-test-configuration.ts' ]; then
        cp 'src/unit-test-configuration.ts.sample' 'src/unit-test-configuration.ts'
    fi

    ./node_modules/jest/bin/jest.js --no-cache
}

run_tox() {
    echo 'Running Tox...'

    # Cleanup
    cd "$REPO_DIR"
    find . -iname "*.pyc" -delete

    cd "$REPO_DIR"/src/pybind/mgr/dashboard/

    mkdir -p .tox
    chmod 777 .tox

    export CEPH_BUILD_DIR=.tox
    tox -e py27-cov,py27-lint

    # Cleanup
    find .tox -maxdepth 1 -iname "py*" -type d -exec chmod -R 777 {} \;
    cd "$REPO_DIR"
    find . -iname "*.pyc" -delete
}


echo 'Running Sanity checks...'

cd "$REPO_DIR"/src/pybind/mgr/dashboard/frontend

npm install

run_npm_lint
run_jest
run_tox

echo 'Sanity checks successfully finished! Congratulations!'
