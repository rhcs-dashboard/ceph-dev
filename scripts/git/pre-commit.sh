#!/bin/bash

set -e

readonly REPO_DIR="$PWD"
readonly PY_FILES=$(git diff --cached --name-only --diff-filter=ACMRTUXB -- "*.py" | tr '\n' ' ')
readonly TS_FILES=$(git diff --cached --name-only --diff-filter=ACMRTUXB -- "*.ts" | tr '\n' ' ')
readonly SCSS_FILES=$(git diff --cached --name-only --diff-filter=ACMRTUXB -- "*.scss" | tr '\n' ' ')
readonly HTML_FILES=$(git diff --cached --name-only --diff-filter=ACMRTUXB -- "*.html" | tr '\n' ' ')

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

run_prettier() {
    echo 'Running Prettier...'
    #printf "$1\n\n" | tr ' ' '\n'

    cd "$REPO_DIR"/src/pybind/mgr/dashboard/frontend

    RECEIVED_FILES=($1)
    for file in "${RECEIVED_FILES[@]}"; do
        echo "$file" | awk -F "/frontend/" '{print $2}' | xargs ./node_modules/.bin/prettier --write
    done

    cd "$REPO_DIR"

    # Add fixes to staging:
    echo "$1" | xargs git add
}

run_ng_lint() {
    echo 'Running "ng lint"...'
    #printf "$1\n\n" | tr ' ' '\n'

    cd "$REPO_DIR"/src/pybind/mgr/dashboard/frontend

    npm run ng lint -- ceph-dashboard ceph-dashboard-e2e --fix

    cd "$REPO_DIR"

    # Add fixes to staging:
    echo "$1" | xargs git add
}

run_jest() {
    echo 'Running Jest...'

    cd "$REPO_DIR"/src/pybind/mgr/dashboard/frontend

    ./node_modules/jest/bin/jest.js --clearCache
    ./node_modules/jest/bin/jest.js
}

run_html_linter() {
    echo 'Running html-linter...'
    #printf "$1\n\n" | tr ' ' '\n'

    cd "$REPO_DIR"/src/pybind/mgr/dashboard/frontend

    ./node_modules/.bin/html-linter --config html-linter.config.json
}


echo 'Running pre-commit hook...'

if [[ ! -z "$PY_FILES" ]]; then
    run_tox
fi

if [[ ! -z "$TS_FILES" || ! -z "$SCSS_FILES" ]]; then
    run_prettier "$TS_FILES$SCSS_FILES"
fi

if [[ ! -z "$TS_FILES" ]]; then
    run_ng_lint "$TS_FILES"

    run_jest
fi

if [[ ! -z "$HTML_FILES" ]]; then
    run_html_linter
fi

echo 'Pre-commit hook successfully finished! Congratulations!'
