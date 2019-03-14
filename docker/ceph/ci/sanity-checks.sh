#!/bin/bash

set -e

readonly REPO_DIR="$PWD"
readonly PYTHON_VERSION=$(grep MGR_PYTHON_VERSION:STRING "$REPO_DIR"/build/CMakeCache.txt | cut -d '=' -f 2)
readonly TRANSLATION_FILE=src/pybind/mgr/dashboard/frontend/src/locale/messages.xlf

run_npm_ci() {
    echo 'Running "npm ci"...'

    cd "$REPO_DIR"/src/pybind/mgr/dashboard/frontend

    npm ci
}

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

    npm run test:ci -- --no-cache

    echo 'All tests passed: OK'
}

run_npm_i18n() {
    echo 'Running "npm i18n"...'

    cd "$REPO_DIR"/src/pybind/mgr/dashboard/frontend

    npm run i18n --if-present

    cd "$REPO_DIR"
    if [[ $(git diff --name-only --diff-filter=M -- "$TRANSLATION_FILE" | wc -l) == 1 ]]; then
        echo "ERROR: uncommitted changes detected in $TRANSLATION_FILE"

        return 1
    fi
}

run_tox() {
    echo 'Running Tox...'

    # Cleanup
    cd "$REPO_DIR"
    find . -iname "*.pyc" -delete

    cd "$REPO_DIR"/src/pybind/mgr/dashboard

    mkdir -p .tox
    chmod 777 .tox

    export CEPH_BUILD_DIR="$PWD"/.tox
    TOX_ARGS="$@"
    if [[ -z "$TOX_ARGS" ]]; then
        # Default behaviour (pre-commit)
        TOX_ARGS='py3-cov,py3-lint'
    fi

    if [[ "$TOX_ARGS" == *'py27-'* && "$PYTHON_VERSION" == '3' ]]; then
        echo 'Python 3 build detected: switching to python 3 tox env.'
        TOX_ARGS=${TOX_ARGS//py27-/py3-}
    elif [[ "$TOX_ARGS" == *'py3-'* && "$PYTHON_VERSION" != '3' ]]; then
        echo 'Python 2 build detected: switching to python 2 tox env.'
        TOX_ARGS=${TOX_ARGS//py3-/py27-}
    fi

    tox -e $TOX_ARGS

    # Cleanup
    find .tox -maxdepth 1 -iname "py*" -type d -exec chmod -R 777 {} \;
    cd "$REPO_DIR"
    find . -iname "*.pyc" -delete
}

run_api_tests() {
    echo 'Running API tests...'

    cd "$REPO_DIR"/build

    rm -rf out dev vstart_runner.log

    cd "$REPO_DIR"/src/pybind/mgr/dashboard

    source ./run-backend-api-tests.sh \
        && run_teuthology_tests "$@"

    echo 'API tests successfully finished! Congratulations!'

    cleanup_teuthology

    echo 'API tests cleanup finished!'
}

run_frontend_e2e_tests() {
    echo 'Running frontend E2E tests...'

    if [[ $(ps -ef | grep -v grep | grep "ng serve" | wc -l) > 0 ]]; then
        ARGS="--dev-server-target"
    else
        ARGS="--host=0.0.0.0"

        cd "$REPO_DIR"/build
        ../src/stop.sh

        /docker/start-ceph.sh
    fi

    /docker/set-web-server-proxy.sh

    cd "$REPO_DIR"/src/pybind/mgr/dashboard/frontend

    npm run e2e -- "$ARGS"
}

run_build_doc() {
  echo 'Running "build-doc"...'

  cd "$REPO_DIR"

  rm -rf "$REPO_DIR/build-doc/virtualenv"

  admin/build-doc
}
