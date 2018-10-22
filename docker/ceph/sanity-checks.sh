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
    echo 'Setting up Python Virtual Env...'

    cd "$REPO_DIR"/src/pybind/mgr/dashboard/
    mkdir -p .tox
    chmod 777 .tox

    PYTHON_VIRTUAL_ENV='.tox/venv-pre-commit'
    if [ -d '/docker' ]; then
        PYTHON_VIRTUAL_ENV="$PYTHON_VIRTUAL_ENV-docker"
    fi
    if [ ! -d "$PYTHON_VIRTUAL_ENV" ]; then
        if [ "$(python -V)" == *"Python 3"* ]; then
            PYTHON_VIRTUAL_ENV="$PYTHON_VIRTUAL_ENV-py3"
            python3 -m venv "$PYTHON_VIRTUAL_ENV"
        else
            PYTHON_VIRTUAL_ENV="$PYTHON_VIRTUAL_ENV-py2"
            virtualenv "$PYTHON_VIRTUAL_ENV"
        fi
    fi

    source "$PYTHON_VIRTUAL_ENV"/bin/activate

    pip install -U pip
    pip install -r requirements.txt

    echo 'Running Tox...'

    export WITH_PYTHON3="OFF"
    export MGR_DASHBOARD_VIRTUALENV="$PYTHON_VIRTUAL_ENV"
    ./run-tox.sh

    # Cleanup
    find .tox -maxdepth 1 -iname "py*" -type d -exec chmod -R 777 {} \;
    cd "$REPO_DIR"
    find . -iname "*.pyc" -delete
}


echo 'Running Sanity checks...'

run_npm_lint
run_jest
run_tox

echo 'Sanity checks successfully finished! Congratulations!'
