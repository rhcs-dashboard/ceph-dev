#!/bin/bash -i

set -e

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

check_browser_console_calls() {
    echo 'Checking browser console calls...'

    cd "$REPO_DIR"

    local TARGET="$@"
    [[ -z "${TARGET}" ]] && TARGET="$REPO_DIR"/src/pybind/mgr/dashboard/frontend/src/app
    local CONSOLE_CALLS=$((echo "${TARGET}" | xargs grep -Eirn "console\..*\(") || echo '')
    if [[ -n "${CONSOLE_CALLS}" ]]; then
        echo "${CONSOLE_CALLS}

ERROR: please remove browser console calls."
        exit 1
    fi
}

run_npm_fix() {
    echo 'Running "npm fix"...'

    cd "$REPO_DIR"/src/pybind/mgr/dashboard/frontend

    npm run fix --if-present
}

run_npm_lint() {
    echo 'Running "npm lint"...'

    cd "$REPO_DIR"/src/pybind/mgr/dashboard/frontend

    npm run lint --silent
}

run_jest() {
    echo 'Running Jest...'

    cd "$REPO_DIR"/src/pybind/mgr/dashboard/frontend

    local JEST_OPTIONS="--maxWorkers=$(nproc --ignore=3)"
    if [[ -n "$@" ]]; then
        [[ "$CEPH_VERSION" -le '15' ]] && npm run test:config --if-present
        npx jest "$@" ${JEST_OPTIONS}
    else
        npm run test:ci -- ${JEST_OPTIONS}
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
    # Nautilus branch.
    if [[ "$(tox -l | grep cov | wc -l)" > 0 ]]; then
        if [[ -z "$TOX_ARGS" ]]; then
            TOX_ARGS='py3-cov,py3-lint,py27-cov,py27-lint'
        elif [[ "${1:0:6}" == 'tests/' ]]; then
            # Run user-defined unit tests
            TOX_ARGS="py3-run pytest $TOX_ARGS"
        fi
    else # Master branch.
        if [[ -z "$TOX_ARGS" ]]; then
            # Default behaviour (pre-commit)
            TOX_ARGS='py3,lint,check'
            [[ "$(tox -l | grep 'openapi-check' | wc -l)" > 0 ]] && TOX_ARGS="${TOX_ARGS},openapi-check"
            echo "Tox environments: ${TOX_ARGS}"
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
    echo 'Running mypy...'

    if [[ "$CEPH_VERSION" -ge 15 ]]; then
        cd "$REPO_DIR"/src/pybind/mgr/rook
        ./generate_rook_ceph_client.sh

        cd "$REPO_DIR"/src/pybind/mgr
        tox -e mypy
        return 0
    fi

    cd "$REPO_DIR"

    if [[ "$PYTHON_VERSION" != 3 || "$CHECK_MYPY" == '0' ]]; then
        echo 'SKIPPED: mypy'
        return 0
    fi

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

    rm -rf "$CEPH_CONF_PATH"/*
    rm -f vstart_runner.log

    # vstart_runner uses /ceph/build cluster path.
    ln -sf "$CEPH_DEV_DIR" /ceph/build/dev
    ln -sf "$CEPH_OUT_DIR" /ceph/build/out
    ln -sf "$CEPH_CONF" /ceph/build/ceph.conf
    ln -sf "$CEPH_CONF_PATH"/keyring /ceph/build/keyring
    if [[ "${IS_CEPH_RPM}" == 1 ]]; then
        ln -s "$CEPH_BIN" /ceph/build/bin
        ln -s "$CEPH_LIB" /ceph/build/lib
        if [[ "$CEPH_VERSION" -le '14' ]]; then
            echo "MGR_PYTHON_VERSION:STRING=${PYTHON_VERSION}" >> /ceph/build/CMakeCache.txt
        fi
    fi

    echo 'API tests environment setup finished!'
}

create_api_tests_cluster() {
    echo 'Creating API tests cluster...'

    setup_api_tests_env

    cd "$REPO_DIR"/src/pybind/mgr/dashboard/frontend
    mkdir -p dist  # Avoid dashboard module crash.
    # Build frontend in background so dashboard is accessible for debug purposes.
    (npm ci && npm run build -- --deleteOutputPath=false ) &

    cd "$REPO_DIR"/src/pybind/mgr/dashboard
    set +e
    source ./run-backend-api-tests.sh

    echo 'API tests cluster created!'
}

run_api_tests() {
    create_api_tests_cluster

    echo 'Running API tests...'

    cd "$REPO_DIR"/src/pybind/mgr/dashboard

    run_teuthology_tests "$@"
    cleanup_teuthology

    echo 'API tests successfully finished! Congratulations!'
}

run_frontend_e2e_tests() {
    echo 'Running frontend E2E tests...'

    cd "$REPO_DIR"/src/pybind/mgr/dashboard/frontend
    npm ci
    npx --no-install cypress -v && WITH_CYPRESS=1 || WITH_CYPRESS=0
    E2E_CMD="npm run e2e:dev"
    if [[ "${WITH_CYPRESS}" == 1 ]]; then
        [[ -n "${BASE_URL}" ]] && export CYPRESS_BASE_URL="${BASE_URL}"
        E2E_CMD="npx cypress run $@ --browser chrome --headless"
    elif [[ "$(npm run | grep e2e:ci | wc -l)" == 1 ]]; then
        E2E_CMD="npm run e2e:ci"
    fi
    export E2E_CMD
    if [[ "$DASHBOARD_DEV_SERVER" != 1 && -z "${BASE_URL}" && -z "${CYPRESS_BASE_URL}" ]]; then
        if [[ $(ps -ef | grep -v grep | grep "ceph-mgr -i" | wc -l) == 0 ]]; then
            cd "$CEPH_CONF_PATH"
            "$REPO_DIR"/src/stop.sh

            /docker/start-ceph.sh
        fi

        BASE_URL=null
        while [[ "${BASE_URL}" == 'null' ]]; do
            export BASE_URL=$("$CEPH_BIN"/ceph mgr services | jq -r .dashboard)
            sleep 1
        done
        if [[ "${WITH_CYPRESS}" == 1 ]]; then
            export CYPRESS_BASE_URL="${BASE_URL}"
        fi
        cd "$REPO_DIR"/src/pybind/mgr/dashboard/frontend
        ANGULAR_VERSION=$(npm run ng version | grep 'Angular: ' | awk '{ print substr($2,1,1) }')
        # In nautilus this flag is required because BASE_URL is not read in protractor config.
        if [[ "$ANGULAR_VERSION" -le 7 ]]; then
            ARGS="$ARGS --baseUrl=$BASE_URL"
        fi
    fi

    cd "$REPO_DIR"/src/pybind/mgr/dashboard/frontend

    ${E2E_CMD} -- ${ARGS}

    echo 'Frontend E2E tests successfully finished! Congratulations!'
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

    [[ "${PYTHON_VERSION}" == 2 ]] && alternatives --set python /usr/bin/python2

    admin/serve-doc
}

# End of sourced section. Do not exit shell when the script has been sourced.
return 2> /dev/null || true

# Execute what has been passed by argument.
"${@}"
