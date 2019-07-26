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

    npm run test:ci --if-present -- --no-cache

    echo 'All tests passed: OK'
}

run_npm_i18n() {
    cd "$REPO_DIR"

    if [[ -n "$(git check-ignore $TRANSLATION_FILE)" ]]; then
        echo 'SKIPPED: npm i18n'
        return 0
    fi

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

run_mypy() {
    cd "$REPO_DIR"

    if [[ "$PYTHON_VERSION" != '3' || "$CHECK_MYPY" == '0' ]]; then
        echo 'SKIPPED: mypy'
        return 0
    fi

    echo 'Running mypy...'

    MYPY_CONFIG_FILE="$REPO_DIR"/src/mypy.ini
    if [[ ! -e "$MYPY_CONFIG_FILE" ]]; then
        echo 'Using FALLBACK mypy.ini'

        MYPY_CONFIG_FILE=/docker/ci/mypy.ini
    fi

    MYPY_ARGS="$@"
    if [[ -z "$MYPY_ARGS" ]]; then
        MYPY_ARGS="$REPO_DIR"/src/pybind/mgr/dashboard
    fi

    mypy --config-file="$MYPY_CONFIG_FILE" --cache-dir=src/.mypy_cache --follow-imports=skip ${MYPY_ARGS}
}

run_api_tests() {
    echo 'Running API tests...'

    cd "$REPO_DIR"/build

    rm -rf "$CEPH_CONF_PATH" && mkdir "$CEPH_CONF_PATH"
    rm -f vstart_runner.log
    ln -sf "$CEPH_DEV_DIR" /ceph/build/dev
    ln -sf "$CEPH_OUT_DIR" /ceph/build/out
    ln -sf "$CEPH_CONF" /ceph/build/ceph.conf
    ln -sf "$CEPH_CONF_PATH"/keyring /ceph/build/keyring

    if [[ -n "$CEPH_RPM_REPO_DIR" ]]; then
        ln -s "$CEPH_BIN" /ceph/build/bin
        ln -s "$CEPH_LIB" /ceph/build/lib
        export TEUTHOLOGY_PYTHON_BIN=/usr/bin/python2
    fi

    cd "$REPO_DIR"/src/pybind/mgr/dashboard

    source ./run-backend-api-tests.sh \
        && run_teuthology_tests "$@"

    echo 'API tests successfully finished! Congratulations!'

    cleanup_teuthology

    echo 'API tests cleanup finished!'
}

run_frontend_e2e_tests() {
    echo 'Running frontend E2E tests...'

    ARGS="--dev-server-target"
    if [[ "$DASHBOARD_DEV_SERVER" != 1 ]]; then
        if [[ $(ps -ef | grep -v grep | grep "ng build" | wc -l) == 0 ]]; then
            export DASHBOARD_DEV_SERVER=0
            export FRONTEND_BUILD_OPTIONS="--deleteOutputPath=false --prod"

            cd "$REPO_DIR"/build
            ../src/stop.sh

            /docker/start-ceph.sh
        fi

        readonly BASE_URL=$(jq -r '.["/api/"].target' "$REPO_DIR"/src/pybind/mgr/dashboard/frontend/proxy.conf.json)
        ARGS="$ARGS --baseUrl=$BASE_URL"
    fi

    cd "$REPO_DIR"/src/pybind/mgr/dashboard/frontend

    npm run e2e -- ${ARGS}
}

run_build_doc() {
  echo 'Running "build-doc"...'

  cd "$REPO_DIR"

  rm -rf "$REPO_DIR/build-doc/virtualenv"

  admin/build-doc
}
