#!/bin/bash

set -e

source /docker/set-env.sh

REPO_DIR=/ceph
[[ "$IS_UPSTREAM" == 1 && "$CEPH_VERSION" -le '14' ]] && PYTHON_VERSION=2 || PYTHON_VERSION=3
TRANSLATION_FILE=src/pybind/mgr/dashboard/frontend/src/locale/messages.xlf

run_npm_ci() {
    echo 'Running "npm ci"...'

    cd "$REPO_DIR"/src/pybind/mgr/dashboard/frontend

    npm ci
}

run_npm_lint_html() {
    echo 'Running "npm lint:html"...'

    cd "$REPO_DIR"/src/pybind/mgr/dashboard/frontend

    npm run lint:html --if-present
}

run_npm_fix() {
    echo 'Running "npm fix"...'

    cd "$REPO_DIR"/src/pybind/mgr/dashboard/frontend

    npm run fix --if-present
}

run_npm_lint() {
    echo 'Running "npm lint"...'

    cd "$REPO_DIR"/src/pybind/mgr/dashboard/frontend

    npm run lint
}

run_jest() {
    echo 'Running Jest...'

    cd "$REPO_DIR"/src/pybind/mgr/dashboard/frontend

    if [[ -n "$@" ]]; then
        npm run test:config
        npx jest "$@"
    else
        npm run test:ci -- --maxWorkers=$(nproc --ignore=2)
    fi

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
    # Nautilus env list.
    if [[ "$(tox -l | grep cov | wc -l)" > 0 ]]; then
        if [[ -z "$TOX_ARGS" ]]; then
            TOX_ARGS='py3-cov,py3-lint'
        elif [[ "${1:0:6}" == 'tests/' ]]; then
            # Run user-defined unit tests
            TOX_ARGS="py3-run pytest $TOX_ARGS"
        else
            TOX_ARGS="py3-$TOX_ARGS"
        fi
        if [[ "$TOX_ARGS" == *'py27-'* && "$PYTHON_VERSION" == 3 ]]; then
            echo 'Python 3 build detected: switching to python 3 tox env.'
            TOX_ARGS=${TOX_ARGS//py27-/py3-}
        elif [[ "$TOX_ARGS" == *'py3-'* && "$PYTHON_VERSION" != 3 ]]; then
            echo 'Python 2 build detected: switching to python 2 tox env.'
            TOX_ARGS=${TOX_ARGS//py3-/py27-}
        fi
        if [[ -n "$CEPH_RPM_REPO_DIR" ]]; then
            TOX_OPTIONS='--sitepackages'
        fi
    else # Master env list.
        if [[ -z "$TOX_ARGS" ]]; then
            # Default behaviour (pre-commit)
            TOX_ARGS='py27,py3,lint,check'
        elif [[ "${1:0:6}" == 'tests/' ]]; then
            # Run user-defined unit tests
            TOX_ARGS="py3 $TOX_ARGS"
        fi
    fi

    find . -name ".coverage" -exec rm -f {} \;

    tox ${TOX_OPTIONS} -e $TOX_ARGS

    # Cleanup
    find .tox -maxdepth 1 -iname "py*" -type d -exec chmod -R 777 {} \;
    cd "$REPO_DIR"
    find . -iname "*.pyc" -delete
}

run_mypy() {
    cd "$REPO_DIR"

    if [[ "$PYTHON_VERSION" != 3 || "$CHECK_MYPY" == '0' ]]; then
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

setup_api_tests_env() {
    echo 'Setting up API tests environment...'

    cd "$REPO_DIR"/build

    mkdir -p "$CEPH_CONF_PATH" && rm -rf "$CEPH_CONF_PATH"/*
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

    echo 'API tests environment setup finished!'
}

create_api_tests_cluster() {
    echo 'Creating API tests cluster...'

    setup_api_tests_env

    cd "$REPO_DIR"/src/pybind/mgr/dashboard
    set +e
    source ./run-backend-api-tests.sh

    echo 'API tests cluster created!'
}

run_api_tests() {
    echo 'Running API tests...'

    setup_api_tests_env

    cd "$REPO_DIR"/src/pybind/mgr/dashboard

    ./run-backend-api-tests.sh "$@"

    echo 'API tests successfully finished! Congratulations!'
}

run_frontend_e2e_tests() {
    echo 'Running frontend E2E tests...'

    ARGS="--dev-server-target"
    if [[ "$DASHBOARD_DEV_SERVER" != 1 ]]; then
        if [[ $(ps -ef | grep -v grep | grep "ceph-mgr -i" | wc -l) == 0 ]]; then
            export DASHBOARD_DEV_SERVER=0
            export FRONTEND_BUILD_OPTIONS="--deleteOutputPath=false --prod"

            cd "$CEPH_CONF_PATH"
            "$REPO_DIR"/src/stop.sh

            /docker/start-ceph.sh
        fi

        export BASE_URL=$(jq -r '.["/api/"].target' "$REPO_DIR"/src/pybind/mgr/dashboard/frontend/proxy.conf.json)
        cd "$REPO_DIR"/src/pybind/mgr/dashboard/frontend
        ANGULAR_VERSION=$(npm run ng version | grep 'Angular: ' | awk '{ print substr($2,1,1) }')
        # In nautilus this flag is required because BASE_URL is not read in protractor config.
        if [[ "$ANGULAR_VERSION" -le 7 ]]; then
            ARGS="$ARGS --baseUrl=$BASE_URL"
        fi
    fi

    cd "$REPO_DIR"/src/pybind/mgr/dashboard/frontend

    npm run e2e -- ${ARGS}
}

run_build_doc() {
  echo 'Running "build-doc"...'

  cd "$REPO_DIR"

  rm -rf "$REPO_DIR/build-doc/virtualenv"

  alternatives --set python /usr/bin/python3

  admin/build-doc
}

run_serve_doc() {
  echo 'Running "serve-doc"...'

  cd "$REPO_DIR"

  alternatives --set python /usr/bin/python2

  admin/serve-doc
}

# End of sourced section. Do not exit shell when the script has been sourced.
return 2> /dev/null || true

# Execute what has been passed by argument.
"${@}"
